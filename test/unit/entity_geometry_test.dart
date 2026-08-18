import 'dart:math' as math;
import 'dart:typed_data';

import 'package:eatwhat_app/v2/features/home/game/entity_geometry.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

Vector2 v(double x, double y) => Vector2(x, y);

void main() {
  group('traceBoundary', () {
    test('traces the outline of a solid rectangle mask', () {
      const width = 10;
      const height = 8;
      final mask = Uint8List(width * height);
      for (var y = 2; y < 6; y++) {
        for (var x = 3; x < 8; x++) {
          mask[y * width + x] = 1;
        }
      }

      final contour = traceBoundary(mask, width, height);

      expect(contour.length, greaterThanOrEqualTo(4));
      for (final point in contour) {
        expect(point.x, inInclusiveRange(3, 7));
        expect(point.y, inInclusiveRange(2, 5));
      }
      // The contour must be closed: the walk returns to its start.
      expect(contour.first, equals(contour.last));
    });

    test('returns empty for an empty mask', () {
      final mask = Uint8List(25);
      expect(traceBoundary(mask, 5, 5), isEmpty);
    });
  });

  group('convexHull', () {
    test('removes interior points and keeps rectangle corners', () {
      final points = [
        v(0, 0),
        v(4, 0),
        v(4, 4),
        v(0, 4),
        v(2, 2), // interior
        v(2, 0), // collinear edge point
      ];

      final hull = convexHull(points);

      expect(hull.length, 4);
      final xs = hull.map((p) => p.x).toSet();
      final ys = hull.map((p) => p.y).toSet();
      expect(xs, containsAll(<double>[0, 4]));
      expect(ys, containsAll(<double>[0, 4]));
    });
  });

  group('reduceToMaxVertices', () {
    test('shrinks a 12-gon to at most 8 vertices', () {
      final points = <Vector2>[
        for (var i = 0; i < 12; i++)
          v(10 * math.cos(i * math.pi / 6), 10 * math.sin(i * math.pi / 6)),
      ];

      final reduced = reduceToMaxVertices(points, 8);

      expect(reduced.length, lessThanOrEqualTo(8));
      expect(reduced.length, greaterThanOrEqualTo(3));
    });
  });

  group('polygonCentroid', () {
    test('computes the center of a square', () {
      final square = [v(0, 0), v(4, 0), v(4, 4), v(0, 4)];

      final centroid = polygonCentroid(square);

      expect(centroid.x, closeTo(2, 1e-9));
      expect(centroid.y, closeTo(2, 1e-9));
    });

    test('centroid of an L-shape lies inside the solid part', () {
      final lShape = [
        v(0, 0),
        v(5, 0),
        v(5, 5),
        v(12, 5),
        v(12, 12),
        v(0, 12),
      ];

      final centroid = polygonCentroid(lShape);

      // The missing corner is the top-right area (x>5, y<5 in this winding).
      expect(centroid.x, lessThan(7));
      expect(centroid.y, greaterThan(5));
    });
  });

  group('decomposeContour', () {
    List<List<Vector2>> convexPartsOf(List<Vector2> contour) {
      final parts = decomposeContour(contour);
      expect(parts, isNotEmpty);
      return parts;
    }

    void expectConvexAndBounded(List<List<Vector2>> parts) {
      for (final part in parts) {
        expect(part.length, inInclusiveRange(3, maxPolygonVertices));
        var sign = 0;
        for (var i = 0; i < part.length; i++) {
          final a = part[i];
          final b = part[(i + 1) % part.length];
          final c = part[(i + 2) % part.length];
          final cross =
              (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
          if (cross.abs() > 1e-9) {
            final crossSign = cross > 0 ? 1 : -1;
            if (sign == 0) sign = crossSign;
            expect(crossSign, equals(sign), reason: 'part must be convex');
          }
        }
      }
    }

    test('compact rectangle yields a single hull part', () {
      final rectangle = [v(0, 0), v(10, 0), v(10, 6), v(0, 6)];

      final parts = convexPartsOf(rectangle);

      expect(parts.length, 1);
      expectConvexAndBounded(parts);
      final area = polygonSignedArea(parts.first).abs();
      expect(area, closeTo(60, 1.0));
    });

    test('L-shape decomposes into convex slabs covering the contour', () {
      final lShape = [
        v(0, 0),
        v(5, 0),
        v(5, 5),
        v(12, 5),
        v(12, 12),
        v(0, 12),
      ];
      final contourArea = polygonSignedArea(lShape).abs(); // 95

      final parts = convexPartsOf(lShape);

      expect(parts.length, greaterThanOrEqualTo(1));
      expectConvexAndBounded(parts);

      final coveredArea = parts.fold<double>(
        0,
        (sum, part) => sum + polygonSignedArea(part).abs(),
      );
      expect(coveredArea, greaterThanOrEqualTo(contourArea * 0.85));
      expect(coveredArea, lessThanOrEqualTo(contourArea * 1.35));
    });

    test('crescent shape decomposes without errors', () {
      // Outer arc (radius 10) and inner arc (radius 8, offset center) forming
      // a bent, thin silhouette similar to a chili or noodle entity.
      final crescent = <Vector2>[
        for (var i = 0; i <= 20; i++)
          v(
            10 * math.cos(math.pi * (0.1 + 0.8 * i / 20)),
            10 * math.sin(math.pi * (0.1 + 0.8 * i / 20)),
          ),
        for (var i = 20; i >= 0; i--)
          v(
            8 * math.cos(math.pi * (0.1 + 0.8 * i / 20)),
            3 + 8 * math.sin(math.pi * (0.1 + 0.8 * i / 20)),
          ),
      ];

      final parts = convexPartsOf(crescent);

      expectConvexAndBounded(parts);
      expect(parts.length, greaterThanOrEqualTo(1));
    });
  });

  group('clipToVerticalSlab', () {
    test('halves a square when clipped to its left slab', () {
      final square = [v(0, 0), v(4, 0), v(4, 4), v(0, 4)];

      final clipped = clipToVerticalSlab(square, 0, 2);

      expect(clipped.length, greaterThanOrEqualTo(3));
      final area = polygonSignedArea(clipped).abs();
      expect(area, closeTo(8, 1e-6));
    });

    test('returns empty when the slab misses the polygon', () {
      final square = [v(0, 0), v(4, 0), v(4, 4), v(0, 4)];

      expect(clipToVerticalSlab(square, 10, 12), isEmpty);
    });
  });

  group('ramerDouglasPeucker', () {
    test('collapses a straight line into its endpoints', () {
      final points = <Vector2>[
        for (var i = 0; i <= 10; i++) v(i.toDouble(), i.toDouble()),
      ];

      final simplified = ramerDouglasPeucker(points, 0.5);

      expect(simplified.length, 2);
      expect(simplified.first, equals(points.first));
      expect(simplified.last, equals(points.last));
    });

    test('keeps prominent corners of a zigzag', () {
      final points = <Vector2>[
        v(0, 0),
        v(5, 0),
        v(5, 5),
        v(0, 5),
      ];

      final simplified = ramerDouglasPeucker(points, 0.5);

      expect(simplified, contains(v(5, 0)));
      expect(simplified, contains(v(5, 5)));
    });
  });

  group('simplifyRing', () {
    test('preserves the anchor extremes of a ring', () {
      final ring = <Vector2>[
        v(0, 0),
        v(2, 0),
        v(4, 0),
        v(4, 2),
        v(4, 4),
        v(2, 4),
        v(0, 4),
        v(0, 2),
        v(0, 1),
        v(0, 0.5),
      ];

      final simplified = simplifyRing(ring, epsilon: 1.0);

      expect(simplified.length, lessThanOrEqualTo(ring.length));
      expect(simplified.first.x, anyOf(equals(0), equals(4)));
      expect(simplified, isNotEmpty);
    });
  });
}
