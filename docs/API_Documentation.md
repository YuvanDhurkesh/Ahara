# Ahara – API Documentation

**Version:** 1.0  
**Target Audience:** Backend developers and third-party integrators  

---

## Table of Contents

- [1. Overview](#1-overview)
- [2. Authentication](#2-authentication)
- [3. Endpoints](#3-endpoints)
  - [3.1 Users](#31-users)
  - [3.2 Listings](#32-listings)
  - [3.3 Orders](#33-orders)
  - [3.4 Notifications](#34-notifications)
  - [3.5 Reviews & Trust](#35-reviews--trust)
  - [3.6 OTP Verification](#36-otp-verification)
  - [3.7 Payments](#37-payments)
  - [3.8 Media Upload](#38-media-upload)
- [4. Data Models](#4-data-models)
- [5. Rate Limits & Security](#5-rate-limits--security)

---

## 1. Overview

**What the API does:**  
The Ahara API provides the backend infrastructure necessary for a role-based food redistribution platform. It handles user identity management, surplus food listings, order coordination (matching buyers with food), volunteer assignment for deliveries, and trust/review mechanisms.

**Base URL:**  
All API endpoints are prefixed with the following base URL:  
`https://api.ahara-app.com/api/v1`  
*(For local development, use `http://localhost:5000/api`)*

---

## 2. Authentication

The Ahara API uses **Firebase Authentication** for secure identity verification. All protected endpoints expect a Firebase ID Token (JWT) in the `Authorization` header.

**Token Usage:**
```http
Authorization: Bearer <Firebase_ID_Token>
```

---

## 3. Endpoints

### 3.1 Users

**Create / Sync User**  
**Endpoint URL:** `/users/create`  
**HTTP Method:** `POST`  
**Description:** Create or sync a user from Firebase after authentication.  
**Request Body Example:**
```json
{
  "email": "user@example.com",
  "name": "Jane Doe",
  "role": "buyer",
  "phone": "9876543210"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "User created successfully",
  "data": { "_id": "651a...", "role": "buyer" }
}
```

**Get User by Firebase UID**  
**Endpoint URL:** `/users/firebase/:uid`  
**HTTP Method:** `GET`  
**Description:** Fetch a user profile by their Firebase UID.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "name": "Jane Doe", "email": "user@example.com", "role": "buyer" }
}
```

**Get User by Phone**  
**Endpoint URL:** `/users/phone/:phone`  
**HTTP Method:** `GET`  
**Description:** Fetch a user profile by their registered phone number.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "name": "Jane Doe", "phone": "9876543210" }
}
```

**Update Volunteer Profile**  
**Endpoint URL:** `/users/:uid/volunteer-profile`  
**HTTP Method:** `PUT`  
**Description:** Update volunteer-specific details (e.g. transport type, docs).  
**Request Body Example:**
```json
{
  "transportMode": "bike",
  "licenseNumber": "ABC123456"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Volunteer profile updated"
}
```

**Update Seller Profile**  
**Endpoint URL:** `/users/:uid/seller-profile`  
**HTTP Method:** `PUT`  
**Description:** Update seller details (FSSAI, business name).  
**Request Body Example:**
```json
{
  "businessName": "Spice House",
  "fssaiNumber": "12345678901234"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Seller profile updated"
}
```

**Update Buyer Profile**  
**Endpoint URL:** `/users/:uid/buyer-profile`  
**HTTP Method:** `PUT`  
**Description:** Update buyer-specific details.  
**Request Body Example:**
```json
{
  "address": "123 Main St"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Buyer profile updated"
}
```

**Update Preferences**  
**Endpoint URL:** `/users/:uid/preferences`  
**HTTP Method:** `PUT`  
**Description:** Update user preferences like dietary needs or language.  
**Request Body Example:**
```json
{
  "language": "en",
  "dietaryPreference": "vegetarian"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Preferences saved"
}
```

**Get Preferences**  
**Endpoint URL:** `/users/:uid/preferences`  
**HTTP Method:** `GET`  
**Description:** Fetch current user preferences.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "language": "en", "dietaryPreference": "vegetarian" }
}
```

**Update Volunteer Availability**  
**Endpoint URL:** `/users/:uid/availability`  
**HTTP Method:** `PUT`  
**Description:** Toggle volunteer availability for deliveries.  
**Request Body Example:**
```json
{
  "isAvailable": true
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Availability updated"
}
```

**Toggle Favorite Listing**  
**Endpoint URL:** `/users/:uid/toggle-favorite-listing`  
**HTTP Method:** `POST`  
**Description:** Add or remove a listing from user favorites.  
**Request Body Example:**
```json
{
  "listingId": "651abc1234def"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Listing added to favorites"
}
```

**Toggle Favorite Seller**  
**Endpoint URL:** `/users/:uid/toggle-favorite-seller`  
**HTTP Method:** `POST`  
**Description:** Add or remove a seller from user favorites.  
**Request Body Example:**
```json
{
  "sellerId": "651abc9876xyz"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Seller added to favorites"
}
```

**Get Favorite Sellers**  
**Endpoint URL:** `/users/:uid/favorite-sellers`  
**HTTP Method:** `GET`  
**Description:** Get the list of the user's favorite sellers.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [
    { "sellerId": "651abc...", "businessName": "Spice House" }
  ]
}
```

---

### 3.2 Listings

**Create Surplus Listing**  
**Endpoint URL:** `/listings/create`  
**HTTP Method:** `POST`  
**Description:** Allows a verified seller to create a new surplus food listing.  
**Request Body Example:**
```json
{
  "foodName": "Mixed Veg Biryani",
  "foodType": "prepared_meal",
  "dietaryType": "vegetarian",
  "totalQuantity": 30,
  "pricing": { "isFree": false, "discountedPrice": 50 }
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Listing created successfully",
  "data": { "listingId": "651abc..." }
}
```

**Update Listing**  
**Endpoint URL:** `/listings/update/:id`  
**HTTP Method:** `PUT`  
**Description:** Update an existing listing's details.  
**Request Body Example:**
```json
{
  "totalQuantity": 20
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Listing updated"
}
```

**Get Active Listings**  
**Endpoint URL:** `/listings/active`  
**HTTP Method:** `GET`  
**Description:** Fetch nearby active food listings.  
**Request Body:** None (Query params used for lat/lng/diet)  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "_id": "651abc...", "foodName": "Biryani" } ]
}
```

**Get Expired Listings**  
**Endpoint URL:** `/listings/expired`  
**HTTP Method:** `GET`  
**Description:** Fetch listings that have passed their pickup window.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "_id": "...", "foodName": "Pastries" } ]
}
```

**Get Completed Listings**  
**Endpoint URL:** `/listings/completed`  
**HTTP Method:** `GET`  
**Description:** Fetch listings successfully redistributed.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "_id": "...", "foodName": "Curry" } ]
}
```

**Get Seller Statistics**  
**Endpoint URL:** `/listings/seller-stats`  
**HTTP Method:** `GET`  
**Description:** Get aggregate sales/redistribution stats for a seller.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "totalItemsRescued": 150, "totalEarnings": 2500 }
}
```

**Relist Listing**  
**Endpoint URL:** `/listings/relist/:id`  
**HTTP Method:** `PUT`  
**Description:** Re-post a previously expired or completed listing.  
**Request Body Example:**
```json
{
  "pickupWindow": { "from": "...", "to": "..." }
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Relisted successfully",
  "data": { "newListingId": "..." }
}
```

**Get Favorite Listings**  
**Endpoint URL:** `/listings/favorites/:uid`  
**HTTP Method:** `GET`  
**Description:** Fetch listings bookmarked by the user.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "_id": "...", "foodName": "Apples" } ]
}
```

**Delete Listing**  
**Endpoint URL:** `/listings/delete/:id`  
**HTTP Method:** `DELETE`  
**Description:** Delete/Remove a listing.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "message": "Listing deleted"
}
```

---

### 3.3 Orders

**Create Order**  
**Endpoint URL:** `/orders/create`  
**HTTP Method:** `POST`  
**Description:** Allows a buyer to claim or purchase a listing.  
**Request Body Example:**
```json
{
  "listingId": "651abc1234def",
  "deliveryMethod": "volunteer"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Order created",
  "data": { "orderId": "..." }
}
```

**Get Volunteer Requests Nearby**  
**Endpoint URL:** `/orders/volunteer/requests/:volunteerId`  
**HTTP Method:** `GET`  
**Description:** Fetch nearby pending delivery requests for a volunteer.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "_id": "...", "pickupAddress": "..." } ]
}
```

**Get Volunteer Orders**  
**Endpoint URL:** `/orders/volunteer/:volunteerId`  
**HTTP Method:** `GET`  
**Description:** Fetch orders assigned to a specific volunteer.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "orderId": "...", "status": "in_transit" } ]
}
```

**Get Buyer Orders**  
**Endpoint URL:** `/orders/buyer/:buyerId`  
**HTTP Method:** `GET`  
**Description:** Fetch order history for a buyer.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "orderId": "...", "status": "delivered" } ]
}
```

**Get Seller Orders**  
**Endpoint URL:** `/orders/seller/:sellerId`  
**HTTP Method:** `GET`  
**Description:** Fetch all orders placed against a seller's listings.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "orderId": "...", "status": "picked_up" } ]
}
```

**Get Order by ID**  
**Endpoint URL:** `/orders/:id`  
**HTTP Method:** `GET`  
**Description:** Fetch full details of a specific order.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "_id": "...", "deliveryMethod": "volunteer", "status": "placed" }
}
```

**Get Order Messages**  
**Endpoint URL:** `/orders/:id/messages`  
**HTTP Method:** `GET`  
**Description:** Fetch chat history attached to an order (e.g., between volunteer and buyer).  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "senderId": "...", "text": "I'm 5 mins away" } ]
}
```

**Update Order Status**  
**Endpoint URL:** `/orders/:id/status`  
**HTTP Method:** `PATCH`  
**Description:** Update order lifecycle status (e.g. from placed to picked_up).  
**Request Body Example:**
```json
{
  "status": "picked_up"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Status updated"
}
```

**Update Order (General)**  
**Endpoint URL:** `/orders/:id`  
**HTTP Method:** `PATCH`  
**Description:** Update arbitrary order fields (e.g. dropoff notes).  
**Request Body Example:**
```json
{
  "dropoffNotes": "Leave at front door"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Order updated"
}
```

**Cancel Order**  
**Endpoint URL:** `/orders/:id/cancel`  
**HTTP Method:** `POST`  
**Description:** Cancel an active order.  
**Request Body Example:**
```json
{
  "reason": "Changed my mind"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Order cancelled"
}
```

**Verify Delivery OTP**  
**Endpoint URL:** `/orders/:id/verify-otp`  
**HTTP Method:** `POST`  
**Description:** Volunteer provides OTP from buyer to complete delivery.  
**Request Body Example:**
```json
{
  "otp": "1234"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Delivery verified successfully"
}
```

**Accept Volunteer Assignment**  
**Endpoint URL:** `/orders/:id/accept`  
**HTTP Method:** `POST`  
**Description:** Allows an available volunteer to accept a delivery request.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "message": "Order assigned to volunteer successfully.",
  "data": {
    "status": "volunteer_assigned"
  }
}
```

**Report Emergency**  
**Endpoint URL:** `/orders/:id/emergency`  
**HTTP Method:** `POST`  
**Description:** Volunteer reports an emergency (e.g. flat tire). Auto-reassigns order.  
**Request Body Example:**
```json
{
  "reason": "Flat tire on the way"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Emergency logged, order returned to pool."
}
```

---

### 3.4 Notifications

**Get User Notifications**  
**Endpoint URL:** `/notifications/user/:userId`  
**HTTP Method:** `GET`  
**Description:** Fetch list of alerts/notifications for a user.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "title": "Order Placed", "body": "Your food was ordered." } ]
}
```

**Get Unread Count**  
**Endpoint URL:** `/notifications/user/:userId/unread-count`  
**HTTP Method:** `GET`  
**Description:** Get integer count of unread notifications.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "unreadCount": 3 }
}
```

**Mark Notification as Read**  
**Endpoint URL:** `/notifications/:id/read`  
**HTTP Method:** `PATCH`  
**Description:** Mark a specific notification as read.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "message": "Notification read"
}
```

**Mark All Notifications Read**  
**Endpoint URL:** `/notifications/user/:userId/read-all`  
**HTTP Method:** `PATCH`  
**Description:** Mark all alerts for a user as read.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "message": "All notifications read"
}
```

**Delete Notification**  
**Endpoint URL:** `/notifications/:id`  
**HTTP Method:** `DELETE`  
**Description:** Remove a notification.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "message": "Notification deleted"
}
```

---

### 3.5 Reviews & Trust

**Create a Review**  
**Endpoint URL:** `/reviews/`  
**HTTP Method:** `POST`  
**Description:** Submit a rating/review for a seller or volunteer after an order.  
**Request Body Example:**
```json
{
  "orderId": "651abc...",
  "targetId": "789xyz...",
  "targetRole": "seller",
  "rating": 5,
  "comment": "Great food!"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Review added"
}
```

**Check if Reviewable**  
**Endpoint URL:** `/reviews/check-reviewable/:orderId`  
**HTTP Method:** `GET`  
**Description:** Check if the current user can leave a review for this order.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": { "isReviewable": true }
}
```

**Get Target User Reviews**  
**Endpoint URL:** `/reviews/target/:targetUserId`  
**HTTP Method:** `GET`  
**Description:** Fetch reviews & average stats for a specific seller/volunteer.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "data": [ { "rating": 5, "comment": "Great food!" } ]
}
```

**Add Review Response**  
**Endpoint URL:** `/reviews/:reviewId/response`  
**HTTP Method:** `POST`  
**Description:** Seller responds to a buyer's review.  
**Request Body Example:**
```json
{
  "response": "Thank you for the kind words!"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Response added"
}
```

**Update Review**  
**Endpoint URL:** `/reviews/:reviewId`  
**HTTP Method:** `PUT`  
**Description:** Edit an existing review.  
**Request Body Example:**
```json
{
  "rating": 4,
  "comment": "Good, but cold."
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Review updated"
}
```

**Delete Review**  
**Endpoint URL:** `/reviews/:reviewId`  
**HTTP Method:** `DELETE`  
**Description:** Delete a review.  
**Request Body:** None  
**Response Example:**
```json
{
  "success": true,
  "message": "Review deleted"
}
```

---

### 3.6 OTP Verification

**Send OTP**  
**Endpoint URL:** `/otp/send`  
**HTTP Method:** `POST`  
**Description:** Send a 6-digit SMS OTP to a phone number.  
**Request Body Example:**
```json
{
  "phone": "9876543210"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "OTP sent"
}
```

**Verify OTP**  
**Endpoint URL:** `/otp/verify`  
**HTTP Method:** `POST`  
**Description:** Validate the entered OTP for a given phone number.  
**Request Body Example:**
```json
{
  "phone": "9876543210",
  "otp": "123456"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "OTP verified successfully"
}
```

---

### 3.7 Payments

**Initialize Payment (Razorpay Order)**  
**Endpoint URL:** `/payments/create-order`  
**HTTP Method:** `POST`  
**Description:** Create a payment order via Razorpay for discounted surplus food.  
**Request Body Example:**
```json
{
  "amount": 50
}
```
**Response Example:**
```json
{
  "success": true,
  "data": { "razorpayOrderId": "order_xyz123", "amount": 5000, "currency": "INR" }
}
```

**Verify Payment**  
**Endpoint URL:** `/payments/verify`  
**HTTP Method:** `POST`  
**Description:** Verify the signature from the Razorpay callback/webhook.  
**Request Body Example:**
```json
{
  "razorpay_order_id": "order_xyz123",
  "razorpay_payment_id": "pay_abc",
  "razorpay_signature": "signature_hash"
}
```
**Response Example:**
```json
{
  "success": true,
  "message": "Payment verified"
}
```

---

### 3.8 Media Upload

**Upload Image**  
**Endpoint URL:** `/upload/`  
**HTTP Method:** `POST`  
**Description:** Upload a photo (multipart/form-data) to cloud storage and retrieve the URL.  
**Request Body Example:**
*(Form Data format)*
`image: [File Binary]`

**Response Example:**
```json
{
  "success": true,
  "data": { "url": "https://storage.provider.com/images/123.jpg" }
}
```

---

## 4. Data Models

### 4.1 User
Represents an individual using the platform. Contains common fields shared across roles.
- **_id:** ObjectId
- **firebaseUid:** String (unique)
- **name:** String
- **email:** String
- **phone:** String
- **role:** Enum (`buyer`, `seller`, `volunteer`, `admin`)
- **isActive:** Boolean

### 4.2 Listing
Represents a batch of surplus food offered by a seller.
- **_id:** ObjectId
- **sellerId:** Ref(User)
- **foodName:** String
- **foodType:** String
- **dietaryType:** String
- **totalQuantity:** Number
- **pricing:** Object (`isFree`, `discountedPrice`)
- **pickupWindow:** Object (`from`, `to`)
- **pickupGeo:** GeoJSON Point
- **status:** Enum (`active`, `claimed`, `expired`)

### 4.3 Order
Represents a claim/purchase made by a buyer.
- **_id:** ObjectId
- **buyerId:** Ref(User)
- **listingId:** Ref(Listing)
- **sellerId:** Ref(User)
- **deliveryMethod:** Enum (`self_pickup`, `volunteer`)
- **volunteerId:** Ref(User) (can be null)
- **status:** Enum (`placed`, `volunteer_assigned`, `picked_up`, `in_transit`, `delivered`, `cancelled`)
- **timeline:** Object (Timestamps for status changes)

### 4.4 Rating
Represents a review given by a buyer at the end of an order lifecycle.
- **_id:** ObjectId
- **orderId:** Ref(Order)
- **raterId:** Ref(User - Buyer)
- **targetId:** Ref(User - Seller or Volunteer)
- **targetRole:** Enum (`seller`, `volunteer`)
- **rating:** Number (1 to 5)
- **comment:** String

---

## 5. Rate Limits & Security

### Authentication & Authorization
- Every API endpoint (except public webhooks or health checks) requires a valid **Firebase ID Token**.
- **Role-Based Access Control (RBAC):** Middleware validates the `role` attached to the user preventing buyers from creating listings, or sellers from accepting volunteer tasks.

### Rate Limits
- To prevent abuse (e.g., spamming listing creations or OTP requests), the API is fronted by a rate limiter.
- **Standard endpoints:** 100 requests per IP per minute.
- **OTP/Verification endpoints:** 5 requests per IP per 10 minutes.

### Input Validation
- All incoming JSON payloads are validated using schemas (e.g., Joi / Mongoose schemas).
- Illegal fields injected into the JSON payload are automatically stripped before reaching the controller.
- Geolocation coordinates are bounded to valid `-90 to 90` and `-180 to 180` ranges.

### Error Handling
- The API uses standardized error responses.
- Internal server errors (500) hide stack traces from the client in production mode, logging them securely on the server instead.
- Meaningful HTTP status codes (`400`, `401`, `403`, `404`, `422`, `429`) are returned alongside human-readable `error` messages.
