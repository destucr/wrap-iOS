# Wrap iOS Technical Documentation
Version: 1.0
Target: iOS 17.0+

## 🏛 Architecture: Feature-Based MVC + Coordinator

We use a modular structure where code is grouped by **Feature** rather than technical layer. This ensures that a developer looking to fix a bug in "Checkout" doesn't have to jump between 5 different folders at the root level.

### Folder Structure
- `Core/`: Singleton managers and shared infrastructure.
  - `Networking/`: `NetworkManager` for API calls.
  - `Navigation/`: `Coordinator` logic.
  - `Cart/`: `CartManager` for persistence logic.
- `Features/`:
  - `Auth/`: Login & Registration.
  - `Catalog/`: Browsing and Product Details.
  - `Checkout/`: Cart UI, Previews, and Payment Success.

### The Coordinator Pattern
Navigation is decoupled from ViewControllers. 
- **Why?** It prevents "Massive View Controllers" and makes deep-linking easy.
- **Implementation:** Every feature VC has a `weak var coordinator: MainCoordinator?` property.

## 💾 Persistence: SwiftData
We use **SwiftData** for order-grade local persistence.
- **Model:** `CartItem` (See `Features/Checkout/Models/CartItem.swift`).
- **Constraint:** `variantId` is marked as `@Attribute(.unique)` to prevent duplicate SKUs in the cart.
- **Lifecycle:** Initialized in `SceneDelegate` and injected into `CartManager.shared`.

## 🎨 UI & Layout
- **SnapKit:** We use a DSL for programmatic constraints to keep the code readable and avoid Merge Conflicts common with Storyboards.
- **Xcode Previews:** Every View Controller includes a `#Preview` block. This is our "Visual Documentation" for future maintenance.
- **Kingfisher:** Asynchronous image loading and disk caching for product assets.
- **Haptics:** `UIImpactFeedbackGenerator` is used for non-disruptive feedback (e.g., adding to cart).

## 📡 Networking
- **NetworkManager**: Centralized URLSession wrapper with automatic Keychain integration for auth tokens.
- **Type Safety**: All responses are mapped to concrete `Codable` structs (e.g., `UserSyncResponse`) to avoid `Any` type-erasure issues.
- **Session Management**: Explicit `logout()` triggers local cache clearing (Keychain + Memory) and notifies the backend to invalidate push tokens.

## 🔐 Environment & Secrets
We handle sensitive configurations in three layers:

1. **Firebase (`GoogleService-Info.plist`):** Automatically managed by the Firebase SDK. Must be added to the project manually.
2. **App Configuration (`Config.plist`):** A custom property list containing public identifiers (API URLs, Public Keys).
   - This file is ignored by Git (`.gitignore`) to prevent credential leakage.
   - A template `Config.plist` should be maintained locally.
3. **Privacy Descriptions (`Info.plist`):** 
   - `NSFaceIDUsageDescription`: Required for biometric login.
   - `NSLocationWhenInUseUsageDescription`: Required for delivery logistics.

## 🛡️ Security & Identity
- **BiometricManager**: Singleton wrapper for `LocalAuthentication`. Supports FaceID and TouchID with fallback to manual credentials.
- **OAuth Sync**: Google Sign-In utilizes "Silent Registration" via the `/user/sync` endpoint, ensuring OAuth users are automatically provisioned in the Postgres database.
- **Strict Auth Guard**: `MainCoordinator` enforces a mandatory token check before showing the main interface, preventing unauthorized view access.

## 🛠 Adding a New Feature
1. Create a new folder under `Features/Name`.
2. Define your `Model` if unique to the feature.
3. Create the `ViewController` with SnapKit and a `#Preview`.
4. Add the navigation method to `MainCoordinator.swift`.
