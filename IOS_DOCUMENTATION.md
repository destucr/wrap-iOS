# Wrap iOS Technical Documentation
Version: 3.0 (Updated for MVVM, Coordinator & SkeletonView)
Target: iOS 17.0+

## 🏛 Architecture: Reactive MVVM + Coordinator

We use a modular, feature-based architecture powered by **RxSwift/Combine** for reactive state management and the **Coordinator Pattern** for navigation decoupling.

### Folder Structure
- `Core/`: Shared infrastructure and singletons.
  - `Networking/`: `NetworkManager` (Rx-enabled) and Feature Services.
  - `Navigation/`: `Coordinator` logic and Sub-coordinators (Home, Auth, etc.).
  - `Cart/`: `CartManager` (Reactive source of truth).
  - `Theme/`: `Brand` definition and `SkeletonView` configuration.
  - `Security/`: `BiometricManager` and `KeychainHelper`.
- `Features/`: Grouped by domain (Auth, Catalog, Home, Checkout, OrderHistory).
  - Each feature follows **MVVM**, separating UI (`ViewController`) from business logic (`ViewModel`).

## ⚡️ Reactive State Management

### 1. Reactive Cart & Auto-Sync
- **Source of Truth:** `CartManager.shared.cartItems` (BehaviorRelay).
- **Auto-Sync:** Changes are debounced and synced to the backend automatically.
- **UI Binding:** Cart counts and badges are reactively updated across the app using Rx subscriptions.

### 2. ViewModel Pattern
- ViewModels handle data fetching and state (e.g., `HomeViewModel`).
- State is exposed via `@Published` properties (Combine) or `BehaviorRelay` (RxSwift).
- ViewControllers bind to these states in `viewDidLoad()`.

## ✨ Loading States: Custom Shimmer (Skeleton)

We use a custom-built **Shimmer (Skeleton) System** powered by `CAGradientLayer` and `CABasicAnimation` for high-performance, predictable loading states.

### Implementation Mandates
- **Namespace:** Access through `UIView` extensions: `.startShimmering()` and `.stopShimmering()`.
- **Reusable Component:** Use the `SkeletonView` class for dedicated shimmering blocks.
- **Visual Design:** Shimmers must match the shape and constraints of the final content to reduce perceived latency.
- **Diffable Integration:** When using Diffable Data Sources, include an `isLoading` flag in your RowItems to trigger state-based shimmer transitions.

## 🛡️ Security & Identity (RBAC)

### Role-Based Access Control
- **Roles:** Customer, Driver, Admin.
- **UI Switching:** `MainCoordinator` dynamically configures the `MainTabBarController` based on the user's role persisted in `UserDefaults` and `AuthManager`.
- **Session Safety:** `NetworkManager` exposes an `authStatus` stream to handle token expiration gracefully.

## 💾 Persistence: SwiftData
- **Model:** `CartItem`.
- **Uniqueness:** `variantId` is the primary key.
- **Lifecycle:** Local data is wiped on logout to maintain multi-user privacy.

## 🛠 Adding a New Feature
1. Create a `Features/Name` directory.
2. Define a `ViewModel` for logic and state.
3. Implement `ViewController` with `isSkeletonable` UI components.
4. Register the new flow in a dedicated `SubCoordinator`.
5. Bind UI to ViewModel using Combine or RxSwift.

## 🌏 Localization
- **Language:** Primary focus is **Indonesian (Bahasa Indonesia)**.
- **Standard:** Use modern Indonesian startup terminology (e.g., "Pesanan" for Order, "Bayar" for Pay).
- **Assets:** Use localized strings in `Assets.xcassets` where possible.
