# Ahara Frontend: Technical Documentation

## 1. Project Overview
Ahara is a high-performance food rescue platform that connects food donors (sellers), recipients (buyers), and logistics partners (volunteers). The application facilitates surplus food discovery and secure delivery through real-time geo-spatial matching and OTP-verified handovers.

## 2. Folder-Level Documentation

| Folder | Responsibility | Key Files | Dependency Notes |
| :--- | :--- | :--- | :--- |
| **config/** | App-wide configuration and environment loading. | `api_config.dart`, `theme_config.dart` | `flutter_dotenv` |
| **core/** | Low-level utilities, global UI components, and localization logic. | `constants.dart`, `localization/` | `intl`, `speech_to_text` |
| **data/models/** | Plain Old Dart Objects (PODO) for data serialization. | `user_model.dart`, `listing_model.dart` | `json_annotation` (if used) |
| **data/providers/** | State management layer using the Provider pattern. | `app_auth_provider.dart`, `order_provider.dart` | `provider` |
| **data/services/** | Network I/O and external service integrations. | `backend_service.dart`, `auth_service.dart` | `http`, `firebase_auth` |
| **features/** | Domain-specific modules (Buyer, Seller, Volunteer flows). | `buyer/`, `seller/`, `volunteer/` | Feature-scoped |

## 3. File-Level Documentation

### Main Infrastructure
- **main.dart**: Application entry point. Handles Firebase initialization, environment loading, and the top-level `AuthWrapper` for role-based routing.
- **backend_service.dart**: Centralized REST API bridge. Implements retry logic and error handling for all Node.js backend interactions.
- **app_auth_provider.dart**: Manages global authentication state, including MongoDB user profile synchronization and Firestore caching.

### Core Features
- **buyer_dashboard_page.dart**: Primary interface for food discovery. Integrates `Geolocator` for proximity-based listing fetching.
- **seller_dashboard_page.dart**: Listing management portal. Handles image uploads to Cloudinary and real-time inventory tracking.
- **volunteer_dashboard_page.dart**: Logistics hub for rescue requests. Facilitates proximity-based task acceptance and OTP verification.

## 4. State Management Documentation
- **Pattern**: Provider (ChangeNotifier-based).
- **Scope**:
    - **AppAuthProvider**: Scoped to the entire app via `MultiProvider` in `main.dart`. Manages User/Profile identity and Login/Logout events.
    - **LanguageProvider**: Controls application-wide localization and UI modes.
    - **Feature Scopes**: Individual providers (e.g., `OrderProvider`) are used within specific navigation sub-trees to manage ephemeral state.
- **Flow**: UI Triggers Action → Provider Method → Service Call → State Update → `notifyListeners()` → UI Rebuild.

## 5. Navigation Documentation
The app uses a hybrid navigation strategy (declarative for root, imperative for deep links).

| Route / Component | Navigation Guard | Arguments | Purpose |
| :--- | :--- | :--- | :--- |
| **AuthWrapper** | Firebase Auth State | N/A | Determines if user goes to Landing or Role-Dashboard. |
| **BuyerDashboard** | `role == "buyer"` | N/A | Landing page for recipients. |
| **OrderConfirmation**| Authenticated | `Order` object | Post-payment summary and OTP display. |
| **TrackingPage** | Active Order | `orderId` | Real-time delivery/pickup status. |

---

