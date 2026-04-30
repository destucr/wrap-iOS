# Wrap iOS Technical Documentation
Version: 2.0 (Updated for RxSwift & RBAC)
Target: iOS 17.0+

## 🏛 Architecture: Reactive Feature-Based MVC + Coordinator

We use a modular structure where code is grouped by **Feature** and powered by **RxSwift** for reactive state management. This ensures data consistency across the app without the fragility of manual notifications.

### Folder Structure
- `Core/`: Singleton managers and shared infrastructure.
  - `Networking/`: `NetworkManager` (Rx-enabled) for API calls.
  - `Navigation/`: `Coordinator` logic and `MainTabBarController` (Role-aware).
  - `Cart/`: `CartManager` (Reactive via `BehaviorRelay`).
  - `Theme/`: `Brand` definition and typography.
  - `Security/`: `BiometricManager` and `KeychainHelper` (Atomic updates).
- `Features/`:
  - `Auth/`: Login & Registration. Models: `AuthResponse`, `UserData`.
  - `Catalog/`: Browsing and Product Details.
  - `Checkout/`: Unified Review Order, Previews, and Payment.
  - `OrderHistory/`: Order list and tracking.

## ⚡️ Reactive State Management (RxSwift)

The app's core state is now reactive to ensure high performance and reliable synchronization.

### 1. Reactive Cart & Automatic Sync
- **Implementation:** `CartManager` uses a `BehaviorRelay<[CartItem]>` as the source of truth.
- **Auto-Sync:** A debounced observer (`2.0s`) automatically triggers `syncWithBackend()` whenever the cart changes. This ensures the server always has the latest items without overwhelming the API.
- **UI Binding:** `CatalogViewController` and `MainTabBarController` bind directly to the `cartItems` stream using **RxCocoa**, eliminating manual `reloadData()` flickering and stale badges.

### 2. Session & Auth Streams
- **NetworkManager:** Exposes an `authStatus: Observable<AuthStatus>` stream.
- **Graceful Expiration:** The UI can reactively transition to the login screen or show alerts when a session becomes unauthorized, preventing "silent pops."

### 3. Stock-Aware UI
- **ProductCell:** Reactively configures interaction based on `qtyOnHand`. If stock is 0, the stepper is disabled and an "Out of Stock" overlay is displayed automatically.

## 🛡️ Security & Identity (RBAC)

### Role-Based Access Control
The app supports multiple user roles (Customer, Driver, Admin).
- **Detection:** The `role` is returned in the `POST /login` response and persisted in `UserDefaults`.
- **UI Switching:** `MainCoordinator` and `MainTabBarController` dynamically configure the interface:
    - **Customer View:** [Shop | Cart | Orders | Profile]
    - **Driver View:** [🚚 Queue | 👤 Profile]
- **Persistence:** `AuthManager.shared.userRole` caches the role to ensure the correct UI loads instantly on "Cold Start."

### Atomic Keychain Management
`KeychainHelper.save` uses an atomic `SecItemUpdate` strategy. If an item exists, it is updated in-place. If missing, it is added. This prevents the "Delete-then-Add" window where tokens could be lost if the app is interrupted.

## 💾 Persistence: SwiftData
We use **SwiftData** for order-grade local persistence.
- **Model:** `CartItem`.
- **Constraint:** `variantId` is marked as `@Attribute(.unique)`.
- **Isolation:** The local cart is explicitly cleared via `CartManager.shared.clear()` during logout to prevent data leaking between accounts.

## 📡 Networking
- **NetworkManager**: Centralized URLSession wrapper with Rx-bridge.
- **Input Cleaning:** `AuthService` automatically trims whitespace and forces lowercase on emails to prevent common simulator typing errors.
- **Swift 6 Safety**: All network models (`Product`, `UserData`, `AuthResponse`) conform to `Sendable` and use `nonisolated` where appropriate for background decoding.

## 🛠 Adding a New Feature
1. Create a new folder under `Features/Name`.
2. Define your `Model` with `Codable` and `Sendable`.
3. If the feature involves list data, use `RxCocoa`'s `rx.items` for binding.
4. Update `MainTabBarController` if the feature requires a new role-specific tab.
