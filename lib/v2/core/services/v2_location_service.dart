import 'package:location/location.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class V2LocationService {
  V2LocationService._internal();
  static final V2LocationService instance = V2LocationService._internal();

  final Location _location = Location();

  Future<GeoPoint> getCurrentLocationOrFallback() async {
    try {
      var serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return _fallback();
        }
      }

      var permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
      }
      if (permission != PermissionStatus.granted &&
          permission != PermissionStatus.grantedLimited) {
        return _fallback();
      }

      final loc = await _location.getLocation();
      final lat = loc.latitude;
      final lng = loc.longitude;
      if (lat == null || lng == null) return _fallback();
      return GeoPoint(latitude: lat, longitude: lng);
    } catch (_) {
      return _fallback();
    }
  }

  GeoPoint _fallback() {
    // 默认北京天安门（和旧 ApiConfig 保持一致）
    return const GeoPoint(latitude: 39.9042, longitude: 116.4074);
  }
}
