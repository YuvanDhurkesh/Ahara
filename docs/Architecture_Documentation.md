# Ahara – Architecture Documentation

**Version:** 1.0  
**Document Type:** Technical Architecture & System Design  

---

## 1. System Overview
The Ahara platform tackles food waste by facilitating the redistribution of surplus food from food providers (sellers) to local consumers (buyers) using volunteers for last-mile delivery. 
- **Goal:** Create a robust, scalable, and responsive ecosystem.
- **Key Features:** Real-time matching, reliable delivery tracking, trusted community environment via verification and ratings.
- **Core Pillars:** Reliability, scalability, and ease of maintenance.

## 2. High-Level Architecture
Ahara uses a **client-server** architectural style built upon **layered architecture** principles.

![System Architecture](./images/architecture-diagram.jpeg)

- **Frontend:** Cross-platform mobile application.
- **API Gateway:** Nginx reverse proxy.
- **Backend:** Monolithic Node.js REST API (designed for future microservice decomposition).
- **Database:** Cloud-hosted MongoDB (NoSQL).
- **Real-Time:** Parallel Socket.IO WebSocket layer for live tracking/notifications.
- **Deployment:** Designed for cloud platforms (e.g., AWS) with load balancing and CI/CD pipelines.

## 3. System Components

### Frontend
- **Platform:** Cross-platform mobile application.
- **Interfaces:** Dedicated dashboards for Sellers, Buyers, and Volunteers.
- **Structure:** Modular architecture with Feature Modules (Auth, Buyer, Seller, Volunteer, Location, Payments) and a Services Layer (backend communication, state management).

### API Gateway / Reverse Proxy
- **Nginx:** Nginx acts as the reverse proxy in front of the Express backend and supports traffic distribution across backend instances when scaling is enabled.
- **Responsibilities:** Handles TLS termination, routing, and distributes traffic across backend instances.

### API Layer
- **Role:** The Express REST API exposes endpoints that enable the mobile application to interact with the backend services.
- **Functionality:** Provides a structured interface for authentication, data retrieval, and complex business operations.

### Backend Services
- **Platform:** Express.js REST API server.
- **Role:** Core application logic engine.
- **Responsibilities:** Business logic, security middleware, and communication coordination.

### Application Hosting
- **AWS Elastic Beanstalk:** AWS Elastic Beanstalk is used to host the backend application and simplify deployment, environment management, and scaling support for the Node.js service.

### Deployment Pipeline
- Source code is maintained in GitHub.
- GitHub Actions implements the CI/CD workflow.
- On successful builds, the application is automatically deployed to AWS Elastic Beanstalk.
- Within the hosting environment, Nginx acts as a reverse proxy routing traffic to the Node.js application.
- PM2 manages the Node.js process lifecycle to ensure application stability and automatic restarts.

### Process Management
- **PM2:** The Node.js backend is managed using PM2, which ensures application reliability by automatically restarting failed processes and supporting multi-instance execution.

### Database Layer
- **Primary Store:** MongoDB Atlas (NoSQL document store).
  - Handles flexible data like diverse user profiles (Seller, Buyer, Volunteer).
  - MongoDB geospatial indexes enable efficient nearby listing searches.

### Real-Time Services
- **Technology:** Socket.IO WebSocket server.
- **Role:** Enables bidirectional real-time communication.
- **Use Cases:** Live delivery tracking, active volunteer matching, instant push notifications.

### External Integrations
- **Firebase:** Firebase issues ID Tokens for authentication; the backend verifies these tokens using the Firebase Admin SDK. Firebase Cloud Messaging (FCM) is used for push notifications.
- **Google Maps Platform:** Geospatial mapping, location autocomplete, and route calculation.
- **Twilio:** SMS and OTP services for secure user identity verification.
- **Cloudinary:** Cloud storage and optimization for images and documents.
- **Razorpay:** Payment gateway tool for discounted surplus food purchases.

## 4. Module Breakdown

- **User Authentication Module:** Manages secure login/registration. Firebase issues an ID Token, and the backend verifies it using the Firebase Admin SDK. Also handles OTP verification (Twilio) and Role-Based Access Control (RBAC).
- **Listing Management Module:** CRUD operations for food listings (location, food type, perishability, status).
- **Volunteer Assignment Module:** Assesses and assigns delivery tasks based on availability, location, transport mode, and trust metrics.
- **Delivery Tracking Module:** Uses Socket.IO to manage order lifecycle states and broadcast real-time GPS coordinates to buyers.
- **Rating & Reputation Module:** Processes feedback to calculate Trust Scores, influencing listing visibility and future assignment priority.
- **Notification Module:** Dispatches in-app alerts and asynchronous push notifications (via FCM) for critical order events.

## 5. Data Flow

### Seller Creates a Listing:
1. Seller submits listing details (photo, quantity, pickup window, location) via the app.
2. Image is uploaded to Cloudinary, returning a secure URL.
3. Payload hits the Listing Management Module via the API Gateway.
4. Business validations check hygiene and completeness.
5. Listing is saved in MongoDB; spatial indexes are updated.
6. Notification Module optionally alerts nearby buyers.

### Buyer Claims Food:
1. Buyer discovers listings via map-based spatial queries.
2. Buyer initiates a claim (POST request to Order Module).
3. Order Module verifies availability and locks the resource.
4. For discounted food, the Payment Module orchestrates checkout via Razorpay.
5. Listing state changes to "Claimed"; volunteer matching pipeline triggers.

### Volunteer Delivers Food:
1. Online volunteers receive delivery requests from the Assignment Module.
2. A volunteer accepts, creating an active Delivery Assignment.
3. Volunteer streams periodic GPS updates via Socket.IO to the backend.
4. Backend broadcasts location via WebSockets to the Buyer's live map.
5. Upon successful hand-off, the order status is updated to completed and the transaction is recorded in the system.

## 6. Scalability Design
- **Stateless Backend:** Enables horizontal scaling across multiple instances behind the Nginx load balancer.
- **Database Scaling:** MongoDB Atlas provides automated scaling and sharding capabilities as data volume increases.

## 7. Security Architecture
- **Authentication:** Firebase issues ID Tokens which are verified by the backend using the Firebase Admin SDK to protect all secure endpoints.
- **Authorization:** Express middleware rigorously enforces Role-Based Access Control (RBAC).
- **Input Validation:** Payloads are strictly validated against schemas to prevent injection/tampering.
- **Rate Limiting:** Intercepts abusive traffic on sensitive routes (e.g., OTP generation).
- **Encryption:** All communication is encrypted over HTTPS/TLS via standard web protocols at the Gateway level.

## 8. Real-Time System (Socket.IO)
- Native integration with the Express backend for low-latency, persistent connections.
- During delivery, GPS coordinates publish to a dynamically created 'order room'.
- Both matching engine and buyer client subscribe to these rooms for instant map updates, eliminating HTTP polling overhead.

## 9. Matching and Route Optimization
- **Matching:** Algorithms use MongoDB `$near` geospatial operators to find proximal volunteers.
- **Scoring:** Evaluates proximity, transport capabilities, and historical Trust Scores.
- **Routing:** Calculates efficient turn-by-turn navigation data using Google Maps APIs.

## 10. Reliability and Fault Handling
- **Retries:** Standard mechanisms with exponential backoff for critical API requests.
- **Failovers:** If a volunteer cancels mid-delivery, the backend triggers immediate re-matching protocols.

## 11. Future Scalability
The modular monolith structure anticipates future transition into distributed microservices:
- **Database Sharding:** Horizontal scaling based on geography or zones.
- **Dedicated Compute Clusters:** Migrating routing/matching to high-throughput streaming platforms (e.g., Apache Kafka).
- **Edge Computing:** Edge caching can be introduced in future versions to reduce latency for region-specific listing access.
- **Offline Synchronization:** Introducing robust local caching and background syncing to support full offline capabilities during network drops.
