import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Collision geometry extracted from a preference entity's alpha silhouette.
///
/// The artwork itself defines the physical footprint: its alpha channel is
/// traced into a contour, simplified, and decomposed into convex parts for
/// Forge2D polygon fixtures. All coordinates are expressed in decoded-image
/// pixels relative to the silhouette centroid so that the body origin, the
/// fixtures, and the rendered sprite stay perfectly aligned while the entity
/// rotates, collides, and settles.
class EntityGeometry {
  EntityGeometry._({
    required this.thumbnail,
    required this.srcPosition,
    required this.srcSize,
    required this.convexParts,
    required this.boundsSize,
    required this.boundsCenterOffset,
    required this.longSidePixels,
  });

  /// Downsampled artwork used for rendering; the 1024px source is far too
  /// large to keep decoded for dozens of entities at once.
  final ui.Image thumbnail;

  /// Silhouette bounding box inside [thumbnail], in thumbnail pixels.
  final Vector2 srcPosition;
  final Vector2 srcSize;

  /// Convex polygon parts in image pixels relative to the silhouette
  /// centroid. Each part has between 3 and [maxPolygonVertices] vertices.
  final List<List<Vector2>> convexParts;

  /// Silhouette bounding box size, in image pixels.
  final Vector2 boundsSize;

  /// Offset from the centroid to the bounding box center, in image pixels.
  final Vector2 boundsCenterOffset;

  /// Length of the bounding box long side, in image pixels.
  final double longSidePixels;

  Sprite buildSprite() => Sprite(
        thumbnail,
        srcPosition: srcPosition,
        srcSize: srcSize,
      );

  // --------------------------------------------------------------------------
  // Asset loading: serialized queue + per-asset cache.
  // --------------------------------------------------------------------------

  static const int _decodeWidth = 512;
  static const int _thumbnailSide = 256;
  static const int _maskTargetResolution = 256;
  static const int _alphaThreshold = 28;

  static final Map<String, EntityGeometry> _cache = {};
  static final Map<String, Future<EntityGeometry?>> _inFlight = {};

  /// Three serialized lanes so a burst of new entities loads quickly without
  /// decoding more than a few large sprites at the same time.
  static final List<Future<void>> _lanes =
      List<Future<void>>.generate(3, (_) => Future<void>.value());
  static int _laneIndex = 0;

  /// Loads (and caches) the geometry for [assetName] located at [assetPath].
  ///
  /// Loads share a small worker pool so dozens of entities appear quickly
  /// while peak decode memory stays bounded. Returns null when the asset is
  /// missing or has no opaque pixels; callers should fall back to a simple
  /// shape.
  static Future<EntityGeometry?> load(
    String assetName,
    String assetPath,
  ) {
    final cached = _cache[assetName];
    if (cached != null) return Future.value(cached);

    final pending = _inFlight[assetName];
    if (pending != null) return pending;

    final lane = _laneIndex++ % _lanes.length;
    final task = _lanes[lane].then((_) => _compute(assetName, assetPath));
    _lanes[lane] = task.then<void>((_) {}, onError: (_) {});
    _inFlight[assetName] = task;
    task.whenComplete(() => _inFlight.remove(assetName));
    return task;
  }

  static Future<EntityGeometry?> _compute(
    String assetName,
    String assetPath,
  ) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(),
        targetWidth: _decodeWidth,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final geometry = await fromImage(image);
        if (geometry != null) {
          _cache[assetName] = geometry;
        }
        return geometry;
      } finally {
        image.dispose();
      }
    } catch (error) {
      debugPrint('Entity geometry failed for $assetPath: $error');
      return null;
    }
  }

  /// Extracts geometry from a decoded [image]. Returns null when the image
  /// has no visible pixels above the alpha threshold.
  static Future<EntityGeometry?> fromImage(ui.Image image) async {
    final byteData = await image.toByteData();
    if (byteData == null) return null;

    final width = image.width;
    final height = image.height;
    final pixels = byteData.buffer.asUint8List();
    final stride = math.max(
      1,
      math.min(width, height) ~/ _maskTargetResolution,
    );
    final maskWidth = width ~/ stride;
    final maskHeight = height ~/ stride;

    // Downsample the alpha channel into a coarse occupancy mask.
    final mask = Uint8List(maskWidth * maskHeight);
    var minX = maskWidth.toDouble();
    var maxX = -1.0;
    var minY = maskHeight.toDouble();
    var maxY = -1.0;
    for (var my = 0; my < maskHeight; my++) {
      final y = my * stride + stride ~/ 2;
      for (var mx = 0; mx < maskWidth; mx++) {
        final x = mx * stride + stride ~/ 2;
        final alpha = pixels[(y * width + x) * 4 + 3];
        if (alpha > _alphaThreshold) {
          mask[my * maskWidth + mx] = 1;
          if (mx < minX) minX = mx.toDouble();
          if (mx > maxX) maxX = mx.toDouble();
          if (my < minY) minY = my.toDouble();
          if (my > maxY) maxY = my.toDouble();
        }
      }
    }
    if (maxX < minX || maxY < minY) return null;

    // Trace and simplify the outer silhouette contour.
    final boundary = traceBoundary(mask, maskWidth, maskHeight);
    if (boundary.length < 3) return null;
    final contour = <Vector2>[
      for (final point in boundary) Vector2(point.x * stride, point.y * stride),
    ];
    final simplified = simplifyRing(contour, epsilon: 2.6 * stride);
    if (simplified.length < 3) return null;

    final parts = decomposeContour(simplified);
    if (parts.isEmpty) return null;

    // Re-anchor everything on the silhouette centroid so the body origin
    // matches the center of mass that Forge2D computes from the fixtures.
    final centroid = polygonCentroid(simplified);
    final relativeParts = <List<Vector2>>[
      for (final part in parts)
        <Vector2>[for (final vertex in part) vertex - centroid],
    ];

    final boundsMin = Vector2(minX * stride, minY * stride);
    final boundsMax = Vector2((maxX + 1) * stride, (maxY + 1) * stride);
    final boundsSize = boundsMax - boundsMin;
    final boundsCenter = (boundsMin + boundsMax) * 0.5;
    final longSide = math.max(boundsSize.x, boundsSize.y);
    if (longSide <= 0) return null;

    final thumbnail = await _downscale(image, _thumbnailSide);
    final scaleX = thumbnail.width / width;
    final scaleY = thumbnail.height / height;
    final srcPosition = Vector2(
      boundsMin.x * scaleX,
      boundsMin.y * scaleY,
    );
    final srcSize = Vector2(
      boundsSize.x * scaleX,
      boundsSize.y * scaleY,
    );

    return EntityGeometry._(
      thumbnail: thumbnail,
      srcPosition: srcPosition,
      srcSize: srcSize,
      convexParts: relativeParts,
      boundsSize: boundsSize,
      boundsCenterOffset: boundsCenter - centroid,
      longSidePixels: longSide,
    );
  }

  static Future<ui.Image> _downscale(ui.Image image, int maxSide) async {
    final longest = math.max(image.width, image.height);
    final scale = math.min(1.0, maxSide / longest);
    final targetWidth = math.max(1, (image.width * scale).round());
    final targetHeight = math.max(1, (image.height * scale).round());
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
    return recorder.endRecording().toImage(targetWidth, targetHeight);
  }
}

/// Maximum polygon vertex count supported by Forge2D's PolygonShape.
const int maxPolygonVertices = 8;

// --------------------------------------------------------------------------
// Geometry primitives (pure functions, unit-testable).
// --------------------------------------------------------------------------

/// Clockwise offsets for an 8-connected neighborhood in a y-down grid:
/// E, SE, S, SW, W, NW, N, NE.
const List<int> _kNeighborOffsets = [
  1, 0, //
  1, 1, //
  0, 1, //
  -1, 1, //
  -1, 0, //
  -1, -1, //
  0, -1, //
  1, -1, //
];

/// Traces the outer boundary of the occupancy [mask] with Moore-neighbor
/// tracing and returns the contour in mask coordinates.
List<Vector2> traceBoundary(Uint8List mask, int width, int height) {
  var start = -1;
  for (var i = 0; i < mask.length; i++) {
    if (mask[i] != 0) {
      start = i;
      break;
    }
  }
  if (start < 0) return const [];

  var currentX = start % width;
  var currentY = start ~/ width;
  final startX = currentX;
  final startY = currentY;

  final points = <Vector2>[Vector2(currentX.toDouble(), currentY.toDouble())];
  // The scan found the topmost-left solid pixel, so the pixel to its west is
  // guaranteed background; use it as the initial backtrack point.
  var backtrackX = currentX - 1;
  var backtrackY = currentY;

  final maxSteps = 8 * (width + height);
  var steps = 0;
  while (steps++ < maxSteps) {
    final direction = _directionIndex(
      backtrackX - currentX,
      backtrackY - currentY,
    );
    var advanced = false;
    for (var step = 1; step <= 8; step++) {
      final probe = (direction + step) % 8;
      final nextX = currentX + _kNeighborOffsets[probe * 2];
      final nextY = currentY + _kNeighborOffsets[probe * 2 + 1];
      if (nextX < 0 || nextY < 0 || nextX >= width || nextY >= height) {
        continue;
      }
      if (mask[nextY * width + nextX] == 0) continue;

      // The neighbor checked just before the solid one stays as the new
      // backtrack point.
      final previous = (probe + 7) % 8;
      backtrackX = currentX + _kNeighborOffsets[previous * 2];
      backtrackY = currentY + _kNeighborOffsets[previous * 2 + 1];
      currentX = nextX;
      currentY = nextY;
      points.add(Vector2(nextX.toDouble(), nextY.toDouble()));
      advanced = true;
      break;
    }
    if (!advanced) break; // Isolated single pixel.
    if (currentX == startX && currentY == startY) break;
  }
  return points;
}

int _directionIndex(int dx, int dy) {
  for (var i = 0; i < 8; i++) {
    if (_kNeighborOffsets[i * 2] == dx &&
        _kNeighborOffsets[i * 2 + 1] == dy) {
      return i;
    }
  }
  return 0;
}

/// Simplifies a closed ring with Ramer-Douglas-Peucker, anchored on the two
/// extreme-x vertices so the ring's widest span is always preserved.
List<Vector2> simplifyRing(List<Vector2> ring, {required double epsilon}) {
  if (ring.length <= 16) return List<Vector2>.of(ring);

  var minIndex = 0;
  var maxIndex = 0;
  for (var i = 1; i < ring.length; i++) {
    if (ring[i].x < ring[minIndex].x) minIndex = i;
    if (ring[i].x > ring[maxIndex].x) maxIndex = i;
  }
  if (minIndex == maxIndex) return List<Vector2>.of(ring);

  final chainA = _chainAlong(ring, minIndex, maxIndex);
  final chainB = _chainAlong(ring, maxIndex, minIndex);
  final simplifiedA = ramerDouglasPeucker(chainA, epsilon);
  final simplifiedB = ramerDouglasPeucker(chainB, epsilon);
  if (simplifiedA.length < 2 || simplifiedB.length < 2) {
    return List<Vector2>.of(ring);
  }
  return <Vector2>[
    ...simplifiedA,
    // Drop the duplicated anchor vertices at both ends of chain B.
    ...simplifiedB.sublist(1, simplifiedB.length - 1),
  ];
}

List<Vector2> _chainAlong(List<Vector2> ring, int from, int to) {
  final out = <Vector2>[];
  var index = from;
  while (true) {
    out.add(ring[index]);
    if (index == to) break;
    index = (index + 1) % ring.length;
  }
  return out;
}

/// Standard Ramer-Douglas-Peucker simplification for an open point chain.
List<Vector2> ramerDouglasPeucker(List<Vector2> points, double epsilon) {
  if (points.length <= 2) return List<Vector2>.of(points);

  final first = points.first;
  final last = points.last;
  var farIndex = -1;
  var farDistance = 0.0;
  for (var i = 1; i < points.length - 1; i++) {
    final distance = _perpendicularDistance(points[i], first, last);
    if (distance > farDistance) {
      farDistance = distance;
      farIndex = i;
    }
  }
  if (farIndex < 0 || farDistance <= epsilon) {
    return <Vector2>[first, last];
  }
  final left = ramerDouglasPeucker(points.sublist(0, farIndex + 1), epsilon);
  final right = ramerDouglasPeucker(points.sublist(farIndex), epsilon);
  return <Vector2>[
    ...left.sublist(0, left.length - 1),
    ...right,
  ];
}

double _perpendicularDistance(
  Vector2 point,
  Vector2 lineStart,
  Vector2 lineEnd,
) {
  final dx = lineEnd.x - lineStart.x;
  final dy = lineEnd.y - lineStart.y;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared < 1e-12) {
    return point.distanceTo(lineStart);
  }
  final numerator =
      (dy * point.x - dx * point.y + lineEnd.x * lineStart.y -
              lineEnd.y * lineStart.x)
          .abs();
  return numerator / math.sqrt(lengthSquared);
}

/// Decomposes a simple polygon into convex parts with at most
/// [maxPolygonVertices] vertices each, suitable for PolygonShape fixtures.
///
/// Compact outlines are replaced by their convex hull; concave outlines are
/// sliced into vertical slabs whose hulls jointly approximate the contour.
List<List<Vector2>> decomposeContour(List<Vector2> contour) {
  final hull = convexHull(contour);
  if (hull.length < 3) return const [];

  final hullArea = polygonSignedArea(hull).abs();
  final contourArea = polygonSignedArea(contour).abs();
  if (hullArea < 1e-6 || contourArea < 1e-6) return const [];

  final convexity = contourArea / hullArea;
  if (convexity >= 0.86) {
    final reduced = reduceToMaxVertices(hull, maxPolygonVertices);
    return reduced.length >= 3 ? <List<Vector2>>[reduced] : const [];
  }

  var minX = double.infinity;
  var maxX = double.negativeInfinity;
  for (final point in contour) {
    if (point.x < minX) minX = point.x;
    if (point.x > maxX) maxX = point.x;
  }

  final deficit = (1.0 - convexity).clamp(0.0, 1.0);
  final slabCount = (2 + deficit * 6).round().clamp(2, 4);
  final parts = <List<Vector2>>[];
  for (var i = 0; i < slabCount; i++) {
    final x0 = minX + (maxX - minX) * i / slabCount;
    final x1 = minX + (maxX - minX) * (i + 1) / slabCount;
    final clipped = clipToVerticalSlab(contour, x0, x1);
    if (clipped.length < 3) continue;
    final slabHull = convexHull(clipped);
    if (slabHull.length < 3) continue;
    final reduced = reduceToMaxVertices(slabHull, maxPolygonVertices);
    if (reduced.length >= 3 &&
        polygonSignedArea(reduced).abs() > contourArea * 0.05) {
      parts.add(reduced);
    }
  }

  if (parts.isEmpty) {
    final reduced = reduceToMaxVertices(hull, maxPolygonVertices);
    if (reduced.length >= 3) parts.add(reduced);
  }
  return parts;
}

/// Clips a polygon to the vertical slab `x0 <= x <= x1` using
/// Sutherland-Hodgman clipping against two half planes.
List<Vector2> clipToVerticalSlab(
  List<Vector2> polygon,
  double x0,
  double x1,
) {
  final left = _clipHalfPlane(polygon, x0, keepGreaterOrEqual: true);
  if (left.isEmpty) return const [];
  return _clipHalfPlane(left, x1, keepGreaterOrEqual: false);
}

List<Vector2> _clipHalfPlane(
  List<Vector2> polygon,
  double limit, {
  required bool keepGreaterOrEqual,
}) {
  final out = <Vector2>[];
  for (var i = 0; i < polygon.length; i++) {
    final current = polygon[i];
    final next = polygon[(i + 1) % polygon.length];
    final currentInside = keepGreaterOrEqual
        ? current.x >= limit
        : current.x <= limit;
    final nextInside = keepGreaterOrEqual
        ? next.x >= limit
        : next.x <= limit;
    if (currentInside) out.add(current);
    if (currentInside != nextInside) {
      final t = (limit - current.x) / (next.x - current.x);
      out.add(
        Vector2(limit, current.y + (next.y - current.y) * t),
      );
    }
  }
  return out;
}

/// Andrew's monotone chain convex hull. Collinear points are removed.
List<Vector2> convexHull(List<Vector2> points) {
  final sorted = List<Vector2>.of(points)
    ..sort((a, b) {
      if (a.x != b.x) return a.x.compareTo(b.x);
      return a.y.compareTo(b.y);
    });
  if (sorted.length < 3) return sorted;

  List<Vector2> buildHalf(Iterable<Vector2> input) {
    final half = <Vector2>[];
    for (final point in input) {
      while (half.length >= 2 &&
          _cross(half[half.length - 2], half[half.length - 1], point) <= 0) {
        half.removeLast();
      }
      half.add(point);
    }

    return half;
  }

  final lower = buildHalf(sorted);
  final upper = buildHalf(sorted.reversed);
  lower.removeLast();
  upper.removeLast();
  return <Vector2>[...lower, ...upper];
}

/// Shrinks a convex polygon to at most [max] vertices by repeatedly removing
/// the vertex whose removal loses the least area.
List<Vector2> reduceToMaxVertices(List<Vector2> hull, int max) {
  final points = List<Vector2>.of(hull);
  while (points.length > max) {
    var removeIndex = 0;
    var smallestLoss = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final previous = points[(i - 1 + points.length) % points.length];
      final next = points[(i + 1) % points.length];
      final loss = _cross(previous, points[i], next).abs() * 0.5;
      if (loss < smallestLoss) {
        smallestLoss = loss;
        removeIndex = i;
      }
    }
    points.removeAt(removeIndex);
  }
  return points;
}

double _cross(Vector2 o, Vector2 a, Vector2 b) =>
    (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);

/// Shoelace signed area; sign depends on winding direction.
double polygonSignedArea(List<Vector2> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    sum += a.x * b.y - b.x * a.y;
  }
  return sum * 0.5;
}

/// Polygon centroid via the standard area-weighted shoelace formula.
Vector2 polygonCentroid(List<Vector2> polygon) {
  var sumX = 0.0;
  var sumY = 0.0;
  for (final point in polygon) {
    sumX += point.x;
    sumY += point.y;
  }
  if (polygon.isEmpty) return Vector2.zero();
  final average = Vector2(sumX / polygon.length, sumY / polygon.length);

  var twiceArea = 0.0;
  var centroidX = 0.0;
  var centroidY = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    final cross = a.x * b.y - b.x * a.y;
    twiceArea += cross;
    centroidX += (a.x + b.x) * cross;
    centroidY += (a.y + b.y) * cross;
  }
  if (twiceArea.abs() < 1e-9) return average;
  return Vector2(centroidX / (3 * twiceArea), centroidY / (3 * twiceArea));
}
