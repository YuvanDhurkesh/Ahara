# Ahara - Full Project Documentation Report

## 1. Executive Summary
**Ahara** is a role-aware mobile application designed to safely redistribute surplus food from  food providers (restaurants, events, institutional kitchens) to individuals and organizations in need (NGOs, community kitchens, low-income individuals). 

The platform bridges the gap between food surplus and food insecurity, heavily focusing on reducing food waste, ensuring safe consumption, and maintaining accountability among all users through a transparent rating and verification system.

**One-Line Engineering Summary:**  
*Ahara leverages a cross-platform mobile architecture with a scalable REST backend to deliver a secure, role-based food redistribution system prioritizing safety, accountability, and sustainability.*

---

## 2. Core Objectives
- **Reduce Food Waste:** Rescue perfectly edible food before it is discarded.
- **Support Food Insecurity:** Provide an easy platform to access free or heavily discounted meals.
- **Logistics Optimization:** Utilize an intelligent volunteer-driven delivery system to facilitate the last-mile transfer.
- **Accountability & Trust:** Employ a community-driven rating system, identity verification, and food safety checks.
- **Social & Environmental Impact:** Contribute to lowering CO₂ emissions and fostering sustainable consumption.

---

## 3. Technology Stack

### 3.1 Mobile Application (Frontend)
- **Framework:** Flutter (Android)
- **Language:** Dart
- **State Management:** Provider
- **Routing:** GoRouter (Role-based declarative navigation)
- **Networking:** Dio (Advanced HTTP client with interceptors)

### 3.2 Backend Server
- **Runtime Environment:** Node.js
- **Framework:** Express.js 
- **Architecture:** Stateless REST API
- **Authentication:** Firebase Authentication (JWT-based)

### 3.3 Database
- **Database:** MongoDB Atlas (Cloud-hosted NoSQL)
- **ODM:** Mongoose (For schema validation and relationship mapping)

### 3.4 DevOps & Cloud Infrastructure
- **Deployment:** AWS Elastic Beanstalk
- **Process Management:** PM2 (Node.js ecosystem)
- **CI/CD:** GitHub Actions (Automated testing, linting, and deployment)

### 3.5 Integrations
- **Twilio:** Used for SMS OTP verification during registration.
- **Razorpay:** For discounted payment gateways.
- **Map & Location:** Geolocation tracking and distance logic for logistics.

---

## 4. User Roles & Ecosystem

Ahara operates with three distinct user personas, each with specific capabilities tailored for their part in the pipeline.

### 4.1 Sellers (Food Providers)
*Restaurants, Cafes, Cloud Kitchens, Event Managers, Cafeterias, Pet Shops*
- **Role:** They list surplus food detailing quantity, dietary type, preparation time, and remaining shelf life.
- **Verification:** Require 14-digit FSSAI numbers for safety compliance.
- **Capabilities:** Check incoming orders, track volunteer delivery status, and view earned trust ratings.

### 4.2 Buyers (Receivers)
*Individuals, NGOs, Community Kitchens*
- **Role:** Browse live surplus listings on an interactive map.
- **Capabilities:** Filter listings by diet (Veg, Vegan, Jain), distance, rating, or cost (Free vs Discounted).
- **Logistics Selection:** Can choose to self-pickup or request volunteer delivery.

### 4.3 Volunteers (Delivery Partners)
*Individuals utilizing Car, Bike, Cycle, or Walk for delivery*
- **Role:** Enable last-mile delivery. They accept "Rescue Requests" and transport food from the Seller to the Buyer.
- **Verification:** Strict KYC implementation (Aadhaar verification), age restrictions for motorized drivers, and OTP validations.
- **Capabilities:** Set online/offline availability, trace directions, confirm pickup/drop-off, and earn achievement badges (e.g., "Top Star").

---

## 5. Key System Workflows

### 5.1 Food Listing Lifecycle
1. **Creation:** A verified seller publishes a new food item with properties: *Name, Type, Diet, Price (Free/Discount), Preparation Time, Hygiene Status*.
2. **Browsing:** Active listings dynamically populate on the buyers' map, utilizing geographical proximity.
3. **Claiming:** A buyer places an order.
4. **Processing (Volunteer Case):** 
   - A nearby active volunteer receives a push notification.
   - The volunteer accepts the order.
   - The volunteer navigates to the seller, picks up the food, and confirms the pickup.
   - The volunteer drives to the buyer, submits an OTP to complete delivery.
5. **Completion & Review:** Both the seller and volunteer receive star ratings from the buyer.

---

## 6. API Architecture & Structure
The Ahara backend exposes a robust Express.js API designed around clear modular boundaries.

* **Users Module (`/users`):** Handles registration, synchronization with Firebase, profile updates by role, and toggling availability.
* **Listings Module (`/listings`):** Manages CRUD operations for active surplus food. Filters are deeply integrated for geolocated retrieval.
* **Orders Module (`/orders`):** Orchestrates the claiming process. Features specific state updates spanning from `placed`, `volunteer_assigned`, `picked_up`, `in_transit`, to `delivered`.
* **Notifications Module (`/notifications`):** Manages real-time alerts.
* **Reviews Module (`/reviews`):** Validates and stores reviews tied strictly to completed orders.
* **OTP Module (`/otp`):** Triggers phone validation tokens independently.

---

## 7. Security, Trust & Verification Pipeline

**Identity Verification (e-KYC):** 
Ahara employs a progressive verification structure. While initial registration relies on SMS OTP, Volunteers face rigorous Aadhaar-based e-KYC.

**Role-Based Access Control (RBAC):**
Firebase ID tokens validate all requests to secure API boundaries, ensuring a buyer cannot access seller-only modification endpoints.

**Food Safety Controls:**
All listings implement a calculated `Rescue Window`. A dynamic timeline evaluates the absolute time limit based on the preparation time to minimize health risks. Expired listings are continuously purged or disabled automatically.

**Community-Driven Quality Control:**
Following delivery completion, the dual-rating mechanism provides a public historical record (*Trust Score*). Subpar users are flagged for administrative investigation based on continuous low scores.

---

## 8. Continuous Integration & Deployment (CI/CD)
The project promotes code resilience through automated GitHub Actions running on every Push or Pull Request directly resolving to the Main loop:

1. **Static Analysis:** `flutter analyze` runs extensively across UI codebases.
2. **Automated Unit Testing:** Jest operates against backend controllers, utilizing an in-memory MongoDB structure to safely isolate side-effects.
3. **Automated CD (AWS):** Validated pull requests merged to `main` trigger an automated deployment to AWS Elastic Beanstalk.
4. **Zero Downtime:** Changes apply immediately via PM2 seamless restarts.

---

## 9. Conclusion
The Ahara architecture establishes a highly scalable and robust system. By integrating automated delivery assignment, geolocated live mapping, robust verification, and strong error boundary controls, the project stands out as a high-social-impact utility. Ahara operates as a secure modern solution addressing global sustainability goals alongside public health & poverty aid.
