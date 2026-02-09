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
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'description': description,
      'status': status.name,
      'businessType': businessType?.name,
    };
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: json['id'],
      foodName: json['foodName'],
      foodType: FoodType.values.byName(json['foodType']),
      quantityValue: (json['quantityValue'] as num).toDouble(),
      quantityUnit: json['quantityUnit'],
      redistributionMode: RedistributionMode.values.byName(
        json['redistributionMode'],
      ),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      preparedAt: DateTime.parse(json['preparedAt']),
      expiryTime: DateTime.parse(json['expiryTime']),
      hygieneStatus: HygieneStatus.values.byName(json['hygieneStatus']),
      locationAddress: json['locationAddress'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      imageUrl: json['imageUrl'],
      description: json['description'] ?? "",
      status: ListingStatus.values.byName(json['status']),
      businessType: json['businessType'] != null
          ? BusinessType.values.byName(json['businessType'])
          : null,
    );
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
