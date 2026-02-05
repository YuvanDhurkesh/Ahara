class MockStore {
  final String id;
  final String name;
  final String type;
  final String category;
  final String image;
  final List<String> badges;
  final String price;
  final String? oldPrice;
  final String? discount;
  final String rating;
  final bool isFree;
  final String area;
  final String city;
  final String address;
  final List<String> ingredients;
  final Map<String, double> reviews; // Collection, Quality, Variety, Quantity

  MockStore({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.image,
    required this.badges,
    required this.price,
    this.oldPrice,
    this.discount,
    required this.rating,
    required this.isFree,
    required this.area,
    required this.city,
    required this.address,
    required this.ingredients,
    required this.reviews,
  });
}

final List<MockStore> allMockStores = [
  MockStore(
    id: "1",
    name: "Sunshine Delights",
    type: "Bakery & Cafe",
    category: "Bread & pastries",
    image:
        "https://images.unsplash.com/photo-1509440159596-0249088772ff?q=80&w=800&auto=format&fit=crop",
    badges: ["Super Popular", "Freshly Baked"],
    price: "₹125",
    oldPrice: "₹250",
    discount: "50% OFF",
    rating: "4.8",
    isFree: false,
    area: "Koramangala",
    city: "Bangalore",
    address: "4th Block, 80 Feet Rd, Koramangala, Bengaluru, Karnataka 560034",
    ingredients: ["Wheat Flour", "Sugar", "Butter", "Yeast", "Organic Milk"],
    reviews: {
      "Collection": 4.5,
      "Quality": 4.9,
      "Variety": 4.2,
      "Quantity": 4.0,
    },
  ),
  MockStore(
    id: "2",
    name: "Cozette Cloud Kitchen",
    type: "Cloud Kitchen",
    category: "Meals",
    image:
        "https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=800&auto=format&fit=crop",
    badges: ["Delivery Only", "Top Rated"],
    price: "₹75",
    oldPrice: "₹150",
    discount: "50% OFF",
    rating: "4.5",
    isFree: false,
    area: "Indiranagar",
    city: "Bangalore",
    address:
        "12th Main Rd, HAL 2nd Stage, Indiranagar, Bengaluru, Karnataka 560038",
    ingredients: [
      "Brown Rice",
      "Lentils",
      "Seasonal Veggies",
      "Cold-pressed Oil",
    ],
    reviews: {
      "Collection": 4.0,
      "Quality": 4.7,
      "Variety": 3.8,
      "Quantity": 4.8,
    },
  ),
  MockStore(
    id: "3",
    name: "The Daily Meal",
    type: "Restaurant",
    category: "Meals",
    image:
        "https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=800&auto=format&fit=crop",
    badges: ["Super Popular"],
    price: "₹90",
    oldPrice: "₹180",
    discount: "Lunch Deal",
    rating: "4.7",
    isFree: false,
    area: "HSR Layout",
    city: "Bangalore",
    address: "27th Main Rd, Sector 2, HSR Layout, Bengaluru, Karnataka 560102",
    ingredients: ["Basmati Rice", "Paneer", "Butter Sauce", "Garlic", "Ginger"],
    reviews: {
      "Collection": 4.2,
      "Quality": 4.8,
      "Variety": 4.5,
      "Quantity": 4.3,
    },
  ),
  MockStore(
    id: "4",
    name: "Pet Paradise",
    type: "Pet Food Store",
    category: "Pet food",
    image:
        "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?q=80&w=800&auto=format&fit=crop",
    badges: ["Surplus Stock"],
    price: "₹225",
    oldPrice: "₹450",
    discount: "50% OFF",
    rating: "4.9",
    isFree: false,
    area: "Koramangala",
    city: "Bangalore",
    address: "5th Block, Koramangala, Bengaluru, Karnataka 560034",
    ingredients: ["Chicken", "Rice", "Carrots", "Vitamins", "Minerals"],
    reviews: {
      "Collection": 4.8,
      "Quality": 4.9,
      "Variety": 4.6,
      "Quantity": 5.0,
    },
  ),
  MockStore(
    id: "5",
    name: "Grand Gala Catering",
    type: "Catering Service",
    category: "Meals",
    image:
        "https://images.unsplash.com/photo-1555244162-803834f70033?q=80&w=800&auto=format&fit=crop",
    badges: ["Event Surplus", "High Volume"],
    price: "FREE",
    rating: "4.6",
    isFree: true,
    area: "Indiranagar",
    city: "Bangalore",
    address: "Double Rd, Indiranagar, Bengaluru, Karnataka 560008",
    ingredients: ["Exotic Veggies", "Traditional Spices", "Ghee", "Nuts"],
    reviews: {
      "Collection": 4.9,
      "Quality": 4.5,
      "Variety": 4.8,
      "Quantity": 4.9,
    },
  ),
  MockStore(
    id: "6",
    name: "The Free Pantry",
    type: "Essential Groceries",
    category: "Groceries",
    image:
        "https://images.unsplash.com/photo-1542838132-92c53300491e?q=80&w=800&auto=format&fit=crop",
    badges: ["Community Driven"],
    price: "FREE",
    rating: "5.0",
    isFree: true,
    area: "HSR Layout",
    city: "Bangalore",
    address: "19th Main Rd, Sector 1, HSR Layout, Bengaluru, Karnataka 560102",
    ingredients: ["Rice", "Wheat Flour", "Lentils", "Cooking Oil", "Salt"],
    reviews: {
      "Collection": 5.0,
      "Quality": 4.8,
      "Variety": 4.5,
      "Quantity": 5.0,
    },
  ),
  MockStore(
    id: "7",
    name: "Royal Event Management",
    type: "Event Food Redistribution",
    category: "Meals",
    image:
        "https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?q=80&w=800&auto=format&fit=crop",
    badges: ["Wedding Surplus", "Fresh"],
    price: "FREE",
    rating: "4.4",
    isFree: true,
    area: "Koramangala",
    city: "Bangalore",
    address: "Outer Ring Rd, Koramangala, Bengaluru, Karnataka 560037",
    ingredients: ["Biryani", "Raita", "Salad", "Desserts", "Cold Drinks"],
    reviews: {
      "Collection": 4.5,
      "Quality": 4.3,
      "Variety": 4.7,
      "Quantity": 5.0,
    },
  ),
  MockStore(
    id: "8",
    name: "Harvest Cafe",
    type: "Cafe",
    category: "Vegan",
    image:
        "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=800&auto=format&fit=crop",
    badges: ["Vegan Friendly", "Eco Friendly"],
    price: "₹40",
    oldPrice: "₹200",
    discount: "80% OFF",
    rating: "4.7",
    isFree: false,
    area: "Indiranagar",
    city: "Bangalore",
    address: "100 Feet Rd, Indiranagar, Bengaluru, Karnataka 560038",
    ingredients: ["Tofu", "Quinoa", "Avocado", "Kale", "Lemon Tahini"],
    reviews: {
      "Collection": 4.2,
      "Quality": 4.9,
      "Variety": 4.6,
      "Quantity": 4.0,
    },
  ),
  MockStore(
    id: "9",
    name: "The Grill Cloud",
    type: "Cloud Kitchen",
    category: "Non-vegetarian",
    image:
        "https://images.unsplash.com/photo-1544025162-d76694265947?q=80&w=800&auto=format&fit=crop",
    badges: ["Juicy Steaks", "Late Night"],
    price: "₹180",
    oldPrice: "₹450",
    discount: "60% OFF",
    rating: "4.3",
    isFree: false,
    area: "Jayanagar",
    city: "Bangalore",
    address: "9th Block, Jayanagar, Bengaluru, Karnataka 560069",
    ingredients: ["Chicken Breast", "Peppercorn", "Rosemary", "Garlic Butter"],
    reviews: {
      "Collection": 4.0,
      "Quality": 4.5,
      "Variety": 3.5,
      "Quantity": 4.8,
    },
  ),
  MockStore(
    id: "10",
    name: "Elite Caterers",
    type: "Professional Catering",
    category: "Meals",
    image:
        "https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=800&auto=format&fit=crop",
    badges: ["Premium Quality", "Zero Waste"],
    price: "₹150",
    oldPrice: "₹300",
    discount: "Flat 50%",
    rating: "4.2",
    isFree: false,
    area: "Jayanagar",
    city: "Bangalore",
    address: "4th Block, Jayanagar, Bengaluru, Karnataka 560041",
    ingredients: ["Fish Curry", "Coconut Rice", "Steam Veggies", "Herbal Tea"],
    reviews: {
      "Collection": 4.3,
      "Quality": 4.5,
      "Variety": 4.0,
      "Quantity": 4.2,
    },
  ),
];
