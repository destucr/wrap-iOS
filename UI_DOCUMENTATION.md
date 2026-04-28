# Wrap UI & UX Documentation
Version: 1.3
Status: Active (Unified Review Order & Spacing Refinement)

## 🏛 1. Information Architecture (IA)

### 1.1 Home Dashboard (`HomeViewController`)
- **Root**: `UICollectionView` using `UICollectionViewCompositionalLayout`.
- **Visual Spacing**: Compositional Layout now uses `interGroupSpacing: 12` for Banners and Personalized feeds.
- **Section Insets**:
    - **Banners**: `0.92` width to show preview of next items.
    - **Grid**: `6pt` item spacing and `10pt` section insets to prevent visual crowding.
- **Category Zoom**: `CategoryCell` uses `.scaleAspectFill` to ensure icons fill the circular container for a "zoomed-in" look.

### 1.2 Unified Checkout Flow (`ReviewOrderViewController`)
- **Architecture**: The Cart and Review Order screens are unified into a single `UITableView` based controller.
- **Components**:
    - **Header**: Navigation item title "Review Order" (or hidden in empty state).
    - **Section 0**: Delivery Address card (`AddressCell`).
    - **Section 1**: Order Items (`ReviewItemCell`).
    - **Section 2**: Pricing Breakdown (`PricingCell`).
- **Tab Bar Integration**: Tab Bar Title is **"Cart"**, but the internally displayed navigation title is **"Review Order"**.
- **Native Gestures**: Supports standard iOS **Swipe-to-Delete** for order items.

### 1.3 Interactive Components
- **Interactive Stepper (`InteractiveStepper`)**: 
    - Custom `UIView` transitioning from `[ + ADD ]` to `[ - ] [ Qty ] [ + ]`.
    - Integrated with `UIImpactFeedbackGenerator` for tactile response.
- **Product Card (`ProductCardView`)**: 
    - Composite view utilizing `Kingfisher` for async image loading.
    - Dynamic data binding: `brand`, `is_halal`, `weight_label`, `qty_on_hand`.

### 1.4 Empty States (`EmptyCartView`)
- **Retention-First Design**: Features a "Rekomendasi Untukmu" (Recommended for You) horizontal feed instead of a dead-end.
- **Dynamic Navigation**: "Mulai Belanja" button dynamically routes back to the main Catalog/Dashboard.
- **State Management**: Navigation Bar titles toggle off in empty states to maximize vertical whitespace.

### 1.5 Product Detail Page (The Trust Builder)
- **Dynamic Fetching**: Fetches full product details from `/catalog/detail/{id}`.
- **Metadata**: Displays `Weight` (using `weight_label` or `unit_of_measure`), `Stock`, and `Temperature`.
- **Direct Cart Toggle**: A sticky footer quantity selector that remains visible regardless of scroll depth.

### 1.6 Identity & Access (`LoginViewController`)
- **Primary Stack**: Vertical `UIStackView` containing Title, Email/Password fields, Login/Biometric buttons, and Google Sign-In.

### 1.7 Profile & Settings (`ProfileViewController`)
- **Identity Header**: Top section with User's Full Name and primary Address.
- **Grouped List**: Account details, Security (Biometric/PIN), Logistics (Saved Addresses), and Logout.

---

## 🔄 2. Granular User Flow (Button-by-Button)

### 2.1 Authentication & Entry
1. **App Launch**: `MainCoordinator` checks `Keychain` for token.
2. **Biometric Path**: App triggers `FaceID/TouchID/OpticID` prompt if available.
3. **Manual Path**: User enters credentials -> `[ Login ]` -> Backend 200 -> `showMainTab()`.

### 2.2 Discovery & Selection
1. **Search**: User taps search bar -> Real-time filtering.
2. **Category**: User taps category icon -> Filters feed.
3. **Add to Cart**: User taps `[ + ADD ]` -> Stepper activates -> Haptic feedback.

### 2.3 Checkout & Fulfillment
1. **View Cart**: User taps the **"Cart"** tab.
2. **Review**: User sees their items, address, and pricing immediately.
3. **Edit**: 
    - User adjusts quantity using the stepper.
    - User **swipes left** on an item to delete it.
4. **Payment**: User taps **"Bayar Sekarang"** to initiate the Xendit payment flow.
5. **Success**: User returns to app -> `MainCoordinator` shows `OrderSuccessViewController`.

### 2.4 Post-Purchase Tracking
1. **Track**: User taps `[ Track Order ]` -> `OrderTrackingViewController` opens.
2. **Live Map**: Shows driver icon moving in real-time on `MKMapView`.

---

## 🏷 3. Labels & Dynamic Values

### 3.1 Order & Delivery States
| State | Label | UX Context |
| :--- | :--- | :--- |
| **Pending** | `RESERVING STOCK` | 15-minute window visualization. |
| **Paid** | `PREPARING` | Warehouse fulfillment. |
| **In Transit** | `ON THE WAY` | Live Map tracking active. |
| **Delivered** | `ARRIVED` | Haptic success trigger. |

### 3.2 Dynamic UI Strings
- **Urgency**: `"Only {n} left"` (Stock < threshold).
- **Value**: `"Rp {price} / {unit}"` (e.g., Rp 12 / gram).

---

## 🎨 4. Design System (Brand Identity)

### 4.1 Colour Palette
| Role | Color Name | Hex / Definition | Use Case |
| :--- | :--- | :--- | :--- |
| **Primary** | **Wrap Emerald** | `#2ECC71` | Primary CTAs. |
| **Secondary** | **System Gray 6** | `UIColor.systemGray6` | Section backgrounds. |
| **Accent** | **System Orange** | `UIColor.systemOrange` | Scarcity labels. |

### 4.2 Typography & Motion
- **Header**: System Bold (24pt).
- **Subheader**: System Semibold (18pt).
- **Haptic Logic**: `Medium` for cart edits, `Success` for handover.

### 4.3 Tab Bar Configuration
| Index | Label | Icon | UX Context |
| :--- | :--- | :--- | :--- |
| **0** | **Shop** | `bag` | Home discovery feed. |
| **1** | **Cart** | `cart` | Unified Review Order screen. |
| **2** | **Order History** | `clock.arrow.circlepath` | Past and active orders. |
| **3** | **Profile** | `person.circle` | Settings and identity. |

### 4.4 Visual Padding Mandates
- **Images**: All cell images must have at least `4pt` internal inset.
- **Stack Spacing**: Minimum `8pt` between vertical labels.
