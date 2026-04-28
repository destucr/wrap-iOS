# Wrap UI & UX Documentation
Version: 1.2
Status: Active (Refined with Component IA & Granular User Flows)

## 🏛 1. Information Architecture (IA)

The Wrap iOS architecture is built on a **Feature-Based MVC + Coordinator** pattern, ensuring high performance and deterministic state transitions.

### 1.1 Home Dashboard (`HomeViewController`)
- **Root**: `UICollectionView` using `UICollectionViewCompositionalLayout`.
- **Data-Driven**: Fully dynamic feed fetched from `/catalog/home`.
- **Sections**:
    - **Header**: Navigation Bar containing `PulseStatusChip` (Left) and `SearchBar` (TitleView).
    - **Section 0 (Banners)**: `BannerCell` dynamic carousel.
    - **Section 1 (Categories)**: `CategoryCell` icon grid.
    - **Sections 2+ (Product Sections)**: `ProductCardView` sections (e.g., "Featured", "Flash Sale").

### 1.2 Interactive Components
- **Interactive Stepper (`InteractiveStepper`)**: 
    - A custom `UIView` that manages its own state transition from `[ + ADD ]` (UIButton) to a horizontal `UIStackView` containing `[ - ]`, `[ QuantityLabel ]`, and `[ + ]`.
    - Integrated with `UIImpactFeedbackGenerator` for tactile response.
- **Product Card (`ProductCardView`)**: 
    - Composite view utilizing `Kingfisher` for async image loading.
    - Dynamic data binding: `weight_label` (Metadata), `qty_on_hand` (ScarcityBadge).

### 1.3 Product Detail Page (The Trust Builder)
- **Dynamic Fetching**: Fetches full product details from `/catalog/detail/{id}`.
- **Metadata**: Displays `Weight` (using `weight_label` or `unit_of_measure`), `Stock`, and `Temperature`.
- **Direct Cart Toggle**: A sticky footer quantity selector that remains visible regardless of scroll depth.

### 1.4 Identity & Access (`LoginViewController`)
- **Primary Stack**: Vertical `UIStackView` containing:
    - `TitleLabel`
    - `EmailTextField` & `PasswordTextField`
    - **Login Action Group**: Horizontal `UIStackView` with `LoginButton` (80% width) and `BiometricButton` (20% width).
    - `ORLabel` separator.
    - `GoogleSignInButton` (Full width).

### 1.5 Profile & Settings (`ProfileViewController`)
- **Identity Header**: Top section with User's Full Name and primary Address.
- **Grouped List**: 
    - **Account**: `Detail Akun` (Name, Phone, Email).
    - **Security**: `Biometric Toggle`, `PIN Settings`.
    - **Logistics**: `Alamat Tersimpan`.
    - **System**: `Logout`.

---

## 🔄 2. Granular User Flow (Button-by-Button)

### 2.1 Authentication & Entry
1. **App Launch**: `MainCoordinator` checks `Keychain` for token.
2. **Biometric Path**:
    - App detects stored credentials -> Automatically triggers `FaceID/TouchID` prompt.
    - User performs biometric scan -> Success -> `MainCoordinator` executes `showMainTab()`.
3. **Manual Path**:
    - User types Email/Password -> Presses `[ Login ]` button.
    - Backend returns 200 -> `AuthManager` saves credentials to `Keychain` -> `showMainTab()`.
4. **Social Path**:
    - User presses `[ Sign in with Google ]` -> System shows OAuth Sheet.
    - User confirms -> `AuthManager` calls `/user/sync` -> `showMainTab()`.

### 2.2 Discovery & Selection
1. **Search**: User taps `[ Search Indomie... ]` in Navigation Bar -> Keyboard opens -> Results filter in real-time.
2. **Category**: User taps `[ Fresh ]` icon in icon grid -> Filters main feed to show only fresh produce.
3. **Add to Cart**: 
    - User taps `[ + ADD ]` on a product card.
    - Button transforms into `[ - 1 + ]` stepper -> `Medium` haptic pulse.
    - User taps `[ + ]` to increase quantity -> `Light` haptic pulse.

### 2.3 Checkout & Fulfillment
1. **View Cart**: User taps the `[ Shopping Cart Icon ]` in the bottom tab bar.
2. **Preview**: User taps `[ Checkout ]` button in the cart summary.
3. **Address Update**: User taps `[ Change Address ]` -> Updates `Floor/Unit` and `Drop-off Point`.
4. **Confirmation**: User taps `[ Place Order ]` -> `Success` haptic pulse -> App opens Xendit Payment Sheet.
5. **Success**: User returns to app -> `MainCoordinator` shows `OrderSuccessViewController`.

### 2.4 Post-Purchase Tracking
1. **Track**: User taps `[ Track Order ]` button on the success screen.
2. **Live Map**: `OrderTrackingViewController` opens -> `MKMapView` shows driver icon moving in real-time.
3. **Contact**: User taps `[ Message Rider ]` -> Opens pre-filled chat sheet.

---

## 🏷 3. Labels & Dynamic Values

### 3.1 Order & Delivery States
| State | Label | UX Context |
| :--- | :--- | :--- |
| **Pending** | `RESERVING STOCK` | 15-minute window visualization. |
| **Paid** | `PREPARING` | Warehouse/Dark Store fulfillment. |
| **In Transit** | `ON THE WAY` | Live Map tracking active. |
| **Delivered** | `ARRIVED` | Haptic success trigger. |

### 3.2 Dynamic UI Strings
- **Urgency**: `"Only {n} left"` (Shown when stock < threshold).
- **Value**: `"Rp {price} / {unit}"` (e.g., Rp 12 / gram).
- **Feedback**: `"Email unverified"`, `"Connecting to driver..."`.

---

## 🎨 4. Design System (Brand Identity)

### 4.1 Colour Palette
| Role | Color Name | Hex / Definition | Use Case |
| :--- | :--- | :--- | :--- |
| **Primary** | **Wrap Emerald** | `#2ECC71` | Primary CTAs, "Best Value" highlights. |
| **Secondary** | **System Gray 6** | `UIColor.systemGray6` | Card/Section backgrounds. |
| **Accent** | **System Orange** | `UIColor.systemOrange` | Scarcity labels, Flash sales. |
| **Surface** | **White** | `#FFFFFF` | Core UI surfaces. |

### 4.2 Typography & Motion
- **Header**: System Bold (24pt).
- **Subheader**: System Semibold (18pt).
- **Caption**: System Medium (12pt) for "Rp / unit" calculations.
- **Haptic Logic**:
    - `Medium`: Cart add/remove.
    - `Success`: Order handover.
    - `Warning`: Blocked checkout.
- **Skeleton Shimmer**: Mandatory for all async data loads to maintain the "Astro-Grade" feel.
