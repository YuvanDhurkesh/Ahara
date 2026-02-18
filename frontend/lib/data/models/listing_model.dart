import 'package:flutter/foundation.dart';
import '../services/backend_service.dart';

enum FoodType {
  prepared_meal,
  fresh_produce,
  packaged_food,
  bakery_item,
  dairy_product,
}

enum RedistributionMode { free, discounted }

enum HygieneStatus { excellent, good, acceptable }

enum ListingStatus { active, expired, claimed }

enum BusinessType {
  restaurant,
  cafe,
  cloud_kitchen,
  pet_shop,
  event_management,
  cafetaria,
}

class Listing {
  final String id;
  final String foodName;
  final FoodType foodType;
  final double quantityValue;
  final String quantityUnit; // kg, portions, pieces, liters
  final RedistributionMode redistributionMode;
  final double? price; // Required if mode is discounted
  final DateTime preparedAt;
  final DateTime expiryTime;
  final HygieneStatus hygieneStatus;
  final String locationAddress;
  final String? pincode;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String description;
  final ListingStatus status;
  final BusinessType? businessType;

  Listing({
    required this.id,
    required this.foodName,
    required this.foodType,
    required this.quantityValue,
    required this.quantityUnit,
    required this.redistributionMode,
    this.price,
    required this.preparedAt,
    required this.expiryTime,
    required this.hygieneStatus,
    required this.locationAddress,
    this.pincode,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.description,
    required this.status,
    this.businessType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodName': foodName,
      'foodType': foodType.name,
      'quantityValue': quantityValue,
      'quantityUnit': quantityUnit,
      'redistributionMode': redistributionMode.name,
      'price': price,
      'preparedAt': preparedAt.toIso8601String(),
      'expiryTime': expiryTime.toIso8601String(),
      'hygieneStatus': hygieneStatus.name,
      'locationAddress': locationAddress,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'description': description,
      'status': status.name,
      'businessType': businessType?.name,
    };
  }

  /// Get the display image URL for this listing
  /// Returns uploaded image if available, otherwise generates aesthetic food image
  String getDisplayImageUrl() {
    if (imageUrl.isNotEmpty) {
      final formattedUrl = BackendService.formatImageUrl(imageUrl);
      if (BackendService.isValidImageUrl(formattedUrl)) {
        debugPrint("📸 Using uploaded image for '$foodName': $formattedUrl");
        return formattedUrl;
      }
    }
    
    final generatedUrl = BackendService.generateFoodImageUrl(foodName);
    debugPrint("🎨 Using generated image for '$foodName': $generatedUrl");
    return generatedUrl;
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'] as Map<String, dynamic>?;
    final pickupWindow = json['pickupWindow'] as Map<String, dynamic>?;

    return Listing(
      id: json['_id'] ?? json['id'] ?? '',
      foodName: json['foodName'] ?? 'Unknown',
      foodType: _parseFoodType(json['foodType']),
      quantityValue: (json['totalQuantity'] as num?)?.toDouble() ?? 0.0,
      quantityUnit: _extractUnit(json['quantityText'] ?? ''),
      redistributionMode: (pricing?['isFree'] == false)
          ? RedistributionMode.discounted
          : RedistributionMode.free,
      price: (pricing?['discountedPrice'] as num?)?.toDouble(),
      preparedAt: DateTime.tryParse(pickupWindow?['from'] ?? '') ?? DateTime.now(),
      expiryTime: DateTime.tryParse(pickupWindow?['to'] ?? '') ?? DateTime.now(),
      hygieneStatus: _parseHygieneStatus(json['hygieneStatus']),
      locationAddress: json['pickupAddressText'] ?? json['locationAddress'] ?? '',
      pincode: json['pincode']?.toString(),
      latitude: 0.0, // Default for now
      longitude: 0.0, // Default for now
      imageUrl: (json['images'] != null && (json['images'] as List).isNotEmpty)
          ? json['images'][0].toString()
          : '',
      description: json['description'] ?? "",
      status: _parseStatus(json['status']),
      businessType: _parseBusinessType(json['businessType']),
    );
  }

  static FoodType _parseFoodType(dynamic value) {
    if (value == null) return FoodType.prepared_meal;
    try {
      return FoodType.values.byName(value.toString());
    } catch (_) {
      return FoodType.prepared_meal;
    }
  }

  static HygieneStatus _parseHygieneStatus(dynamic value) {
    if (value == null) return HygieneStatus.excellent;
    try {
      return HygieneStatus.values.byName(value.toString());
    } catch (_) {
      return HygieneStatus.excellent;
    }
  }

  static ListingStatus _parseStatus(dynamic value) {
    if (value == null) return ListingStatus.active;
    try {
      if (value == 'completed') return ListingStatus.claimed; // Map backend completed to claimed
      return ListingStatus.values.byName(value.toString());
    } catch (_) {
      return ListingStatus.active;
    }
  }

  static BusinessType? _parseBusinessType(dynamic value) {
    if (value == null) return null;
    try {
      return BusinessType.values.byName(value.toString());
    } catch (_) {
      return null;
    }
  }

  static String _extractUnit(String quantityText) {
    if (quantityText.isEmpty) return 'portions';
    final parts = quantityText.split(' ');
    if (parts.length > 1) return parts.last;
    return 'portions';
  }

  static DateTime calculateExpiryTime(FoodType type, DateTime preparedAt) {
    switch (type) {
      case FoodType.prepared_meal:
        return preparedAt.add(const Duration(hours: 6));
      case FoodType.fresh_produce:
        return preparedAt.add(const Duration(days: 2));
      case FoodType.packaged_food:
        return preparedAt.add(const Duration(days: 30));
      case FoodType.bakery_item:
        return preparedAt.add(const Duration(days: 1));
      case FoodType.dairy_product:
        return preparedAt.add(const Duration(days: 2));
    }
  }
}
