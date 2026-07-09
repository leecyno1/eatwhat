import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';

class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class Money {
  const Money({
    required this.amount,
    this.currency = 'CNY',
  });

  final double amount;
  final String currency;
}

enum ExecutionAvailabilityStatus {
  loading,
  available,
  partial,
  unavailable,
}

enum ExecutionLinkTarget {
  none,
  web,
  app,
}

enum ExecutionPath {
  any,
  cook,
  delivery,
  dineIn,
}

enum ExecutionLocationPreference {
  any,
  nearby,
}

class PairingSelection {
  const PairingSelection({
    required this.category,
    required this.title,
    required this.subtitle,
  });

  final String category;
  final String title;
  final String subtitle;
}

class ExecutionIntent {
  const ExecutionIntent({
    required this.recipe,
    required this.pairings,
    required this.sourceTags,
    this.preferredPath = ExecutionPath.any,
    this.locationPreference = ExecutionLocationPreference.any,
  });

  final RecipeModel recipe;
  final List<PairingSelection> pairings;
  final List<String> sourceTags;
  final ExecutionPath preferredPath;
  final ExecutionLocationPreference locationPreference;
}

class ProviderCapabilityMatrix {
  const ProviderCapabilityMatrix({
    this.supportsDishSearch = false,
    this.supportsMerchantSearch = false,
    this.supportsPrefillCart = false,
    this.supportsMerchantDetail = false,
    this.supportsReservation = false,
    this.supportsNavigation = false,
  });

  final bool supportsDishSearch;
  final bool supportsMerchantSearch;
  final bool supportsPrefillCart;
  final bool supportsMerchantDetail;
  final bool supportsReservation;
  final bool supportsNavigation;

  bool get hasAnyCapability =>
      supportsDishSearch ||
      supportsMerchantSearch ||
      supportsPrefillCart ||
      supportsMerchantDetail ||
      supportsReservation ||
      supportsNavigation;

  static const deliveryUnavailable = ProviderCapabilityMatrix();
}

class ProviderAvailability {
  const ProviderAvailability({
    required this.platform,
    required this.displayName,
    required this.capabilities,
    this.isConfigured = true,
    this.reason,
  });

  final String platform;
  final String displayName;
  final ProviderCapabilityMatrix capabilities;
  final bool isConfigured;
  final String? reason;
}

class RestaurantSearchResult {
  const RestaurantSearchResult({
    required this.id,
    required this.name,
    required this.platform,
    required this.url,
    this.rating,
    this.pricePerPerson,
    this.distanceMeters,
  });

  final String id;
  final String name;
  final String platform;
  final String url;
  final double? rating;
  final Money? pricePerPerson;
  final double? distanceMeters;
}

class DeliverySearchResult {
  const DeliverySearchResult({
    required this.storeId,
    required this.storeName,
    required this.platform,
    required this.url,
    this.deliveryTimeMinutes,
    this.distanceMeters,
  });

  final String storeId;
  final String storeName;
  final String platform;
  final String url;
  final int? deliveryTimeMinutes;
  final double? distanceMeters;
}

class DeliveryMatchResult {
  const DeliveryMatchResult({
    required this.platform,
    required this.providerDisplayName,
    required this.merchantId,
    required this.merchantName,
    required this.dishName,
    required this.url,
    this.productId,
    this.price,
    this.deliveryTimeMinutes,
    this.supportsPrefillCart = false,
    this.note,
    this.source = 'provider',
    this.capabilityReason,
    this.linkTarget = ExecutionLinkTarget.web,
  });

  final String platform;
  final String providerDisplayName;
  final String merchantId;
  final String merchantName;
  final String dishName;
  final String url;
  final String? productId;
  final Money? price;
  final int? deliveryTimeMinutes;
  final bool supportsPrefillCart;
  final String? note;
  final String source;
  final String? capabilityReason;
  final ExecutionLinkTarget linkTarget;
}

class DineInMatchResult {
  const DineInMatchResult({
    required this.platform,
    required this.providerDisplayName,
    required this.merchantId,
    required this.merchantName,
    required this.matchedDishName,
    required this.url,
    this.rating,
    this.pricePerPerson,
    this.distanceMeters,
    this.supportsMerchantDetail = false,
    this.supportsReservation = false,
    this.supportsNavigation = false,
    this.note,
  });

  final String platform;
  final String providerDisplayName;
  final String merchantId;
  final String merchantName;
  final String matchedDishName;
  final String url;
  final double? rating;
  final Money? pricePerPerson;
  final double? distanceMeters;
  final bool supportsMerchantDetail;
  final bool supportsReservation;
  final bool supportsNavigation;
  final String? note;
}

class DeliveryExecutionSnapshot {
  const DeliveryExecutionSnapshot({
    required this.status,
    required this.providerStates,
    required this.matches,
    this.message,
  });

  final ExecutionAvailabilityStatus status;
  final List<ProviderAvailability> providerStates;
  final List<DeliveryMatchResult> matches;
  final String? message;
}

class DineInExecutionSnapshot {
  const DineInExecutionSnapshot({
    required this.status,
    required this.providerStates,
    required this.matches,
  });

  final ExecutionAvailabilityStatus status;
  final List<ProviderAvailability> providerStates;
  final List<DineInMatchResult> matches;
}
