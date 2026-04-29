# Wrap iOS Technical Documentation
Version: 1.3 (Updated for Core Animation & Shimmer)
Target: iOS 17.0+

## 🏛 Architecture: Feature-Based MVC + Coordinator

We use a modular structure where code is grouped by **Feature** rather than technical layer. This ensures that a developer looking to fix a bug in "Checkout" doesn't have to jump between 5 different folders at the root level.

### Folder Structure
- `Core/`: Singleton managers and shared infrastructure.
  - `Networking/`: `NetworkManager` for API calls.
  - `Navigation/`: `Coordinator` logic.
  - `Cart/`: `CartManager` for persistence logic.
  - `Theme/`: `Brand` definition and typography.
  - `Security/`: `BiometricManager` and `KeychainHelper`.
- `Features/`:
  - `Auth/`: Login & Registration. Models: `AuthResponse`, `UserData`.
  - `Catalog/`: Browsing and Product Details. Models: `Product`, `PromoBanner`, `CatalogCategory`.
  - `Checkout/`: Unified Review Order, Previews, and Payment.
    - `Components/`: `EmptyCartView`, `ReviewItemCell`.
    - `ReviewOrderViewController`: The unified Cart + Review screen.

### The Coordinator Pattern
Navigation is decoupled from ViewControllers. 
- **Implementation:** Every feature VC has a `weak var coordinator: MainCoordinator?` property.
- **Refinement:** `showCart()` and `showCheckoutPreview()` now both route to `ReviewOrderViewController`.

## 💾 Persistence: SwiftData
We use **SwiftData** for order-grade local persistence.
- **Model:** `CartItem` (See `Features/Checkout/Models/CartItem.swift`).
- **Constraint:** `variantId` is marked as `@Attribute(.unique)` to prevent duplicate SKUs in the cart.
- **Lifecycle:** Initialized in `SceneDelegate` and injected into `CartManager.shared`.
- **Concurrency:** All models (`Product`, `UserData`, etc.) conform to `Sendable` for Swift 6 safety.

## 🎨 UI & Layout
- **Seamless Navigation**: Implements a custom `UIViewControllerAnimatedTransitioning` to create fluid, shared element transitions (image and title) between product lists and detail views, elevating the perceived quality without massive dependencies.
- **SnapKit:** DSL for programmatic constraints.
- **Unified Checkout:** The Cart and Review Order screens are unified into a single `ReviewOrderViewController` using `UITableView`.
- **Native Gestures:** `ReviewOrderViewController` implements `trailingSwipeActionsConfigurationForRowAt` for native **Swipe-to-Delete** on products.
- **Compositional Layout:** `HomeViewController` uses `interGroupSpacing` and padding insets in its `UICollectionViewCompositionalLayout` to prevent visual crowding.
- **Kingfisher:** Asynchronous image loading and disk caching.
- **Haptics:** `UIImpactFeedbackGenerator` is used for non-disruptive feedback (e.g., adding to cart).
- **Navigation Lifecycle:** To maintain the custom dashboard look while preserving the **Swipe-to-Back** gesture:
    - `HomeViewController`: Hides the navigation bar in `viewWillAppear`.
    - Secondary Screens: Explicitly unhide the navigation bar in `viewWillAppear` to show titles and back buttons.

## 📡 Networking
- **NetworkManager**: Centralized URLSession wrapper with `Keychain` integration.
- **Date Decoding**: Uses a custom `JSONDecoder.dateDecodingStrategy` to handle ISO8601 strings with and without fractional seconds, ensuring compatibility with Go's RFC3339 output.
- **Swift 6 Safety**:
  - All request generic types `T` must conform to `Codable & Sendable`.
  - Async fetching helpers (e.g., `performFetchHome`) are marked `nonisolated` to resolve actor isolation warnings.
- **Type Safety**: Models use specific names like `UserData` and `CatalogCategory` to avoid global naming collisions.
- **Session Management**: Explicit `logout()` triggers local cache clearing (Keychain + Memory) and notifies the backend to invalidate push tokens.

## 🔐 Environment & Secrets
1. **Firebase (`GoogleService-Info.plist`):** Automatically managed by the Firebase SDK.
2. **App Configuration (`Config.plist`):** Custom plist for API URLs and public keys.
3. **Privacy Descriptions (`Info.plist`):** 
   - `NSFaceIDUsageDescription`: Required for biometric login.
   - `NSLocationWhenInUseUsageDescription`: Required for delivery logistics.
   - `UIDesignRequiresCompatibility`: Set to `YES` to ensure layout consistency across modern iOS display variants.

## 🛡️ Security & Identity
- **BiometricManager**: Singleton wrapper for `LocalAuthentication`.
  - **Exhaustivity**: Handles `.touchID`, `.faceID`, and `.opticID` explicitly.
- **OAuth Sync**: Google Sign-In utilizes "Silent Registration" via `/user/sync`.
- **Strict Auth Guard**: `MainCoordinator` enforces mandatory token checks before showing the main interface.

## 🛠 Adding a New Feature
1. Create a new folder under `Features/Name`.
2. Define your `Model` with `Codable` and `Sendable` conformances.
3. Create the `ViewController` (prefer `UITableView` for lists requiring gestures).
4. Add navigation to `MainCoordinator.swift`.
