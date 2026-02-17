# Complete MongoDB Schema - Ahara Food Redistribution App

## Architecture Overview

This schema uses a **split-model architecture** for better separation of concerns:
- **User** - Common authentication and basic info
- **Profile Models** - Role-specific data (SellerProfile, BuyerProfile, VolunteerProfile)
- **Transaction Models** - Listing, Order, Review
- **System Models** - Notification, TrustHistory

---

## Schema Files

### 0. Shared Helper (`_shared.js`)
```javascript
const GeoPointSchema = {
  type: { type: String, enum: ["Point"], default: "Point" },
  coordinates: {
    type: [Number], // [lng, lat]
    validate: {
      validator: (v) => Array.isArray(v) && v.length === 2,
      message: "coordinates must be [lng, lat]"
    }
  }
};
```

### 1. User (Common for all roles)
- `firebaseUid` - Unique Firebase authentication ID
- `role` - buyer/seller/volunteer
- `name`, `phone`, `email`
- `geo` - GeoJSON location for proximity search
- `trustScore` - Only for seller/volunteer (10-100)
- `accountStatus` - active/warned/locked
- `deletedAt` - Soft delete support

**Indexes:** `firebaseUid`, `role`, `phone`, `geo (2dsphere)`, `deletedAt`

### 2. SellerProfile
- `userId` - Reference to User
- `orgName`, `orgType` - Business details
- `businessGeo` - Business location
- `fssai` - Certificate number, URL, verification status
- `payout` - UPI ID, KYC status
- `stats` - avgRating, ratingCount, totalListings, totalOrdersCompleted

**Indexes:** `userId`, `businessGeo (2dsphere)`

### 3. BuyerProfile
- `userId` - Reference to User
- `favouriteSellers` - Array of seller User IDs
- `dietaryPreferences` - vegetarian/vegan/non_veg/jain
- `stats` - totalOrders, cancelledOrders

**Indexes:** `userId`

### 4. VolunteerProfile
- `userId` - Reference to User
- `transportMode` - walk/cycle/bike/car
- `availability` - isAvailable, maxConcurrentOrders
- `verification` - Progressive levels (0-3), license, ID proof
- `ageVerification` - Privacy-friendly age check
- `badge` - tickVerified for top performers
- `stats` - Delivery performance metrics

**Indexes:** `userId`

### 5. Listing
- `sellerId`, `sellerProfileId` - References
- `foodName`, `foodType`, `category`
- `quantityText` - "Serves 10", "5 kg"
- `pricing` - originalPrice, discountedPrice, isFree
- `pickupWindow` - from/to dates
- `pickupGeo` - Pickup location
- `status` - active/expired/cancelled/completed
- `activeOrderId` - Prevents double-booking

**Indexes:** `sellerId`, `pickupGeo (2dsphere)`, `status + pickupWindow.to`

### 6. Order
- `listingId`, `sellerId`, `buyerId`, `volunteerId`
- `fulfillment` - self_pickup/volunteer_delivery
- `status` - 9 states from placed to delivered/cancelled/failed
- `pickup`, `drop` - Geo locations
- `tracking` - Real-time volunteer location
- `pricing`, `payment` - Transaction details
- `handoverOtp` - Delivery confirmation
- `timeline` - Timestamps for each stage

**Indexes:** `listingId`, `sellerId`, `buyerId`, `volunteerId`, `status`

### 7. Review
- `orderId`, `reviewerId`
- `targetType` - seller/volunteer
- `targetUserId` - Who is being reviewed
- `rating` - 1-5 stars
- `comment`, `tags`

**Indexes:** `orderId`, `targetUserId + createdAt`

### 8. Notification
- `userId`, `type`, `title`, `message`
- `data` - Additional payload
- `isRead`, `readAt`

**Indexes:** `userId + isRead + createdAt`

### 9. TrustHistory
- `userId`, `delta`, `reason`
- `orderId` - Related order
- `createdBy` - system/admin

**Indexes:** `userId`

---

## Registration Flow

### Seller Registration
1. Create User document with `role="seller"`, `trustScore=50`
2. Create SellerProfile with business details
3. Upload FSSAI certificate → `fssai.verified=false` (admin approval needed)

### Buyer Registration
1. Create User document with `role="buyer"`, no trustScore
2. Create BuyerProfile

### Volunteer Registration
1. Create User document with `role="volunteer"`, `trustScore=50`
2. Create VolunteerProfile with `verification.level=0`
3. Progressive verification increases level

---

## Key Features

✅ **Geospatial Search** - Find food/volunteers nearby using 2dsphere indexes  
✅ **Trust System** - Audit trail via TrustHistory  
✅ **Progressive Verification** - Volunteers level up with documents  
✅ **Soft Delete** - Users can be recovered  
✅ **Real-time Tracking** - Volunteer location updates  
✅ **Payment Flexibility** - Optional payment fields for MVP  
✅ **Rating System** - Separate for sellers and volunteers  

---

## Next Steps

1. ✅ All schema files created
2. Update `userController.js` to create profile documents
3. Add controllers for Listing, Order, Review
4. Implement trust score calculation logic
5. Add admin panel for FSSAI verification
