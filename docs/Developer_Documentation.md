# Ahara - Developer Documentation

This document explains how developers can run, modify, and deploy the Ahara system. It provides a comprehensive technical overview of the application architecture, code structure, and development workflows.

---

## 1. Technology Stack

### Frontend
- **Framework:** Flutter (Android)
- **Language:** Dart
- **State Management:** Provider
- **Routing:** GoRouter

### Backend
- **Runtime & Framework:** Node.js + Express.js
- **Authentication:** Firebase Authentication (JWT Tokens)
- **Testing:** Jest + Supertest

### Database
- **Database:** MongoDB Atlas (Cloud-hosted NoSQL)
- **ODM:** Mongoose

### Other Services
- **SMS & OTP Services:** Twilio
- **Payment Gateway:** Razorpay
- **Cloud/DevOps Services:** AWS Elastic Beanstalk (Hosting), GitHub Actions (CI/CD)
- **Geolocation:** Google Maps API / Location Services

---

## 2. Project Structure

The project follows a decoupled monolithic architecture with separate repositories/folders for the frontend and backend. 

### Backend Directory Layout
`/backend` contains the Node.js API server.
- `/config` — Environment and database connection configurations.
- `/controllers` — Business logic and request handling. Every route function delegates here.
- `/models` — Mongoose schemas representing database collections (Users, Listings, Orders, etc.).
- `/routes` — Express route definitions mapped to their respective controllers.
- `/services` — Third-party service integrations (Twilio, Razorpay, push notifications).
- `/tests` — Automated unit and integration tests using Jest.
- `/utils` — Reusable helper functions (error handling, data formatting, logic checks).
- `server.js` — Application entry point.

### Frontend Directory Layout
`/frontend` contains the Flutter mobile application. Inside `/frontend/lib`:
- `/core` — Core app configurations, themes, constants, and utilities.
- `/config` — App-wide configuration files (routes, API endpoints).
- `/data` — Data layout operations, local storage, API providers, and repositories for Dio HTTP network requests.
- `/features` — Feature-based modules (Authentication, Dashboard, Map, Settings). Each module handles its own UI and logic.
- `/shared` — Reusable shared UI components, widgets, and generic app layouts.
- `main.dart` — App entry point.

---

## 3. Setup Instructions

Follow these steps to set up the Ahara development environment locally.

### 3.1 Clone Repository
```bash
git clone https://github.com/YuvanDhurkesh/Ahara.git
cd Ahara
```

### 3.2 Backend Setup
1. **Navigate to backend:**
   ```bash
   cd backend
   ```
2. **Install dependencies:**
   ```bash
   npm install
   ```
3. **Configure environment variables:** (See section 4 for `.env` setup).
4. **Start the backend development server:**
   ```bash
   npm run dev
   ```
   *The server runs locally at `http://localhost:5000`.*

### 3.3 Frontend Setup
1. **Navigate to frontend:**
   ```bash
   cd ../frontend
   ```
2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure environment variables:** (See section 4 for `.env` setup).
4. **Run the Flutter app:**
   ```bash
   flutter run
   ```

---

## 4. Environment Variables

You need to create a `.env` file in both the `/backend` and `/frontend` directories to specify environment variables.

### Backend (`/backend/.env`)
```env
PORT=5000
MONGO_URI=your_mongodb_cluster_connection_string
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_virtual_phone_number
FIREBASE_SERVICE_ACCOUNT=your_firebase_admin_sdk_json
```

### Frontend (`/frontend/.env`)
```env
BASE_URL=http://10.0.2.2:5000/api  # Use 10.0.2.2 for Android Emulator, or localhost for web.
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=your_twilio_virtual_phone_number
```

---

## 5. Deployment Instructions

### Automated CI/CD (GitHub Actions)
Deployment is streamlined via GitHub actions automatically. Pushes to the `main` branch trigger continuous integration workflows:
1. Validates Flutter codebase (`flutter analyze` and tests).
2. Runs all Jest Backend specs against an in-memory test database.
3. Automatically pipelines successful backend builds to **AWS Elastic Beanstalk**.

### Manual Backend Deployment (AWS Elastic Beanstalk)
1. Navigate to the AWS Management Console -> Elastic Beanstalk.
2. Initialize a new Node.js environment.
3. Use the EB CLI to deploy:
   ```bash
   eb init -p node.js ahara-backend
   eb create ahara-backend-env
   eb deploy
   ```
4. Set the aforementioned environment variables dynamically via the AWS Elastic Beanstalk Configuration Dashboard (so secrets are not exposed in code).

### Database Setup
1. Open the **MongoDB Atlas Dashboard**.
2. Select your clustered project.
3. Ensure Network Access (IP Whitelist) has `0.0.0.0/0` (for Elastic Beanstalk dynamic IPs) or attach an AWS VPC Peering connection.
4. Retrieve the `MONGO_URI` connection string and pass it to your EB environment variables. 
