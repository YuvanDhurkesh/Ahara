# Ahara - Food Redistribution & Waste Reduction Platform

A **role-aware mobile application** designed to safely redistribute surplus food from **restaurants, events, and institutional kitchens** to **NGOs and community kitchens**.

The platform focuses on **reducing food waste**, **ensuring public health**, and **maintaining accountability** through secure access control, intelligent coordination, and scalable backend services.

---

## Key Objectives
- Reduce edible food waste  
- Ensure safe and timely food redistribution  
- Enable transparent accountability among stakeholders  
- Optimize logistics using intelligent matching  
- Measure social and environmental impact  

---

## Tech Stack

### Mobile Application
- **Flutter** – Cross-platform framework enabling a single codebase for Android and iOS with near-native performance.  
- **Dart** – Strongly typed language optimized for reactive UI and asynchronous operations.  
- **Provider** – Lightweight state management for handling authentication, roles, and global app data.  
- **GoRouter** – Declarative routing for structured and role-based navigation.  
- **Dio** – Advanced HTTP client for secure API communication with interceptors and error handling.

---

### Backend
- **Node.js** – Event-driven runtime supporting scalable and concurrent API handling.  
- **Express.js** – Minimal framework for building structured REST APIs with clear separation of routes and middleware.  
- **Firebase Authentication** – Secure identity management with token-based authentication.

---

### Database
- **MongoDB Atlas** – Cloud-hosted NoSQL database suitable for flexible schemas such as multi-role users, food listings, and audit records.  
- **Mongoose** – ODM for schema validation and simplified database interaction.

---

### Security & Access Control
- **Firebase ID Tokens (JWT)** – Secure API access and session validation.  

**Role-Based Access Control (RBAC):**
- Food Provider (Donor)  
- NGO  
- Volunteer  
- Admin  

---

## Testing Strategy

| Test Type              | Tool Used |
|------------------------|------------|
| Unit Testing           | Flutter Test, Jest |
| API Testing            | Supertest |
| Integration Testing    | End-to-end workflow validation |
| Manual Testing         | Structured Test Case Documentation |

---
## CI/CD Pipeline

### Continuous Integration (CI)
**Tool:** GitHub Actions

The project uses a **GitHub Actions** driven CI pipeline to automate development workflows and maintain code reliability.

Triggered automatically on **Push to main** and **Pull Requests**:

- **Static Analysis:** `flutter analyze` for frontend code quality.
- **Automated Testing:**
  - Backend: `npm test` (Jest) with in-memory MongoDB.
  - Frontend: `flutter test` (Unit/Widget).
- **Dependency Validation:** Ensures `npm install` and `flutter pub get` succeed.
- **Early Failure Detection:** Prevents broken code from merging.

---

### Continuous Deployment (CD)

GitHub Actions pipelines are configured to support controlled deployment workflows to production.

Key capabilities include:

- **Automated Deployment:** Deploys to AWS EC2 only after tests pass.
- **Secure Access:** Uses SSH keys enabling secure remote execution.
- **Zero Downtime:** Uses `pm2` for seamless process restarts.

---

### Deployment Infrastructure
- **Backend Hosting:** AWS EC2 (Ubuntu/Linux)
- **Database Hosting:** MongoDB Atlas
- **Process Management:** PM2 (Node.js)

---

## Cloud Infrastructure
- Managed cloud services minimize operational overhead while supporting scalability.  
- Environment variables used for secure secrets management.  
- Stateless API architecture enables horizontal scaling.  

---

---

## Prerequisites

Before you begin, ensure you have the following installed:
- **Node.js** (v18 or higher) & **npm**
- **Flutter SDK** (v3.10.8 or higher)
- **Dart SDK**
- **MongoDB** (Local or Atlas)
- **Firebase CLI** (for authentication setup)

---

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/YuvanDhurkesh/Ahara.git
cd Ahara
```

### 2. Backend Setup (Node.js)
The backend handles API requests, database interactions, and integrations (Twilio, Razorpay).

1. **Navigate to the backend directory:**
   ```bash
   cd backend
   ```
2. **Install dependencies:**
   ```bash
   npm install
   ```
3. **Configure Environment Variables:**
   Create a `.env` file in the `backend` folder and add the following:
   ```env
   PORT=5000
   MONGO_URI=your_mongodb_connection_string
   TWILIO_ACCOUNT_SID=your_twilio_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   TWILIO_PHONE_NUMBER=your_twilio_number
   ```
4. **Run the server:**
   ```bash
   npm run dev
   ```
   The backend will be running at `http://localhost:5000`.

### 3. Frontend Setup (Flutter)
The frontend is a Flutter-based mobile application.

1. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```
2. **Install dependencies:**
   ```bash
   flutter pub get
   ```
3. **Configure Environment Variables:**
   Create a `.env` file in the `frontend` folder:
   ```env
   BASE_URL=http://localhost:5000/api
   TWILIO_ACCOUNT_SID=your_twilio_sid
   TWILIO_AUTH_TOKEN=your_twilio_token
   TWILIO_PHONE_NUMBER=your_twilio_number
   ```
4. **Run the application:**
   ```bash
   flutter run
   ```

---

## Development Tools
- **Git & GitHub** – Version control and collaborative development  
- **Postman** – API testing and debugging  
- **Docker (Optional)** – Containerized local setup  
- **GitHub Actions** – Automated workflows  

---

## Documentation
- Software Requirements Specification (SRS)  
- Architecture Diagram  
- ER Diagram  
- API Documentation  
- Manual Test Case Reports  

---

## Impact
- Reduces large-scale food wastage  
- Supports food-insecure communities  
- Helps lower CO₂ emissions through redistribution  
- Encourages sustainable and responsible consumption  

---

## Team
Built by a cross-functional engineering team focusing on **trust, logistics optimization, real-time coordination, and sustainability-driven system design**.

---

## One-Line Engineering Summary

> *Ahara leverages a cross-platform mobile architecture with a scalable REST backend to deliver a secure, role-based food redistribution system prioritizing safety, accountability, and sustainability.*
