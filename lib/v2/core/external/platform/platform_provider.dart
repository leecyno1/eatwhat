import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

abstract class PlatformProvider {
  String get platform;
  String get displayName;

  bool get isConfigured;
  ProviderCapabilityMatrix get capabilities;

  Future<List<DineInMatchResult>> searchMerchantCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  });

  Future<List<DeliveryMatchResult>> searchDishCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  });
}
