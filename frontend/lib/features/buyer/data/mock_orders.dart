import '../data/mock_stores.dart';

enum OrderStatus { active, completed, cancelled }

enum OrderType { delivery, pickup }

class MockOrder {
  final String id;
  final MockStore store;
  final OrderStatus status;
  final OrderType type;
  final String date;
  final String total;
  final String itemsSummary;

  // Delivery Specifics
  final String? deliveryTime;
  final String? volunteerName;
  final String? volunteerId; // Added for gamification
  final double? volunteerRating;
  final int? currentStep; // 0: Confirmed, 1: Preparing, 2: Out, 3: Arrived

  MockOrder({
    required this.id,
    required this.store,
    required this.status,
    required this.type,
    required this.date,
    required this.total,
    required this.itemsSummary,
    this.deliveryTime,
    this.volunteerName,
    this.volunteerId,
    this.volunteerRating,
    this.currentStep,
  });
}

final List<MockOrder> mockOrders = [
  // Active Delivery
  MockOrder(
    id: "ORD-001",
    store: allMockStores[0], // Sunshine Delights
    status: OrderStatus.active,
    type: OrderType.delivery,
    date: "Today, 12:30 PM",
    total: "₹131.25",
    itemsSummary: "1x Special Pastry Box",
    deliveryTime: "1:15 PM",
    volunteerName: "Ramesh K.",
    volunteerId: "test_volunteer_123", // Mock ID
    volunteerRating: 4.8,
    currentStep: 2, // Out for delivery
  ),
  // Active Pickup
  MockOrder(
    id: "ORD-002",
    store: allMockStores[5], // Free Pantry
    status: OrderStatus.active,
    type: OrderType.pickup,
    date: "Today, 11:00 AM",
    total: "Free",
    itemsSummary: "1x Essential Kit",
  ),
  // Completed Delivery
  MockOrder(
    id: "ORD-003",
    store: allMockStores[1], // Cozette
    status: OrderStatus.completed,
    type: OrderType.delivery,
    date: "Feb 2, 2026",
    total: "₹78.75",
    itemsSummary: "1x Healthy Meal Bowl",
    volunteerName: "Suresh M.",
  ),
];
