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
... (existing networking)

## 🔐 Environment & Secrets
We handle sensitive configurations in two ways:

1. **Firebase (`GoogleService-Info.plist`):** Contains your Google API keys, Project ID, and client configuration. This file must be manually added to the `Wrap/` directory from the Firebase Console. It is ignored by `.gitignore` in professional setups to prevent secret leakage.
2. **App Environment (`Core/Config/Environment.swift`):** Centralizes internal API keys and URLs.
   - `baseURL`: Points to the Azure VM.
   - `isDevelopment`: Uses compiler flags (`#if DEBUG`) to toggle between sandbox and production environments.

## 🛠 Adding a New Feature
1. Create a new folder under `Features/Name`.
2. Define your `Model` if unique to the feature.
3. Create the `ViewController` with SnapKit and a `#Preview`.
4. Add the navigation method to `MainCoordinator.swift`.
