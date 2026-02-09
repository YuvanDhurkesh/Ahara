enum OrderStatus { pending, confirmed, picked_up, delivered, cancelled }

class Order {
  final String id;
  final String listingId;
  final String buyerId;
  final String? volunteerId;
  final OrderStatus status;
  final double totalAmount;
  final String listingName;
  final String buyerName;
  final String pickupInstructions;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.listingId,
    required this.buyerId,
    this.volunteerId,
    required this.status,
    required this.totalAmount,
    required this.listingName,
    required this.buyerName,
    required this.pickupInstructions,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'listingId': listingId,
      'buyerId': buyerId,
      'volunteerId': volunteerId,
      'status': status.name,
      'totalAmount': totalAmount,
      'listingName': listingName,
      'buyerName': buyerName,
      'pickupInstructions': pickupInstructions,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      listingId: json['listingId'],
      buyerId: json['buyerId'],
      volunteerId: json['volunteerId'],
      status: OrderStatus.values.byName(json['status']),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      listingName: json['listingName'] ?? "Unknown",
      buyerName: json['buyerName'] ?? "Unknown",
      pickupInstructions: json['pickupInstructions'] ?? "",
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
