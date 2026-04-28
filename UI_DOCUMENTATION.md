# Wrap UI & UX Documentation
Version: 1.1
Status: Active (Refined with Zero-Friction & Trust-Building Directives)

## 🏛 1. Information Architecture (IA)

The Wrap interface is optimized for "The 30-Second Shop"—minimizing cognitive load and maximizing fulfillment speed.

### 1.1 Home Dashboard (The 30-Second Shop)
- **Delivery Pulse**: A dynamic status chip next to the user's location (e.g., `"Delivery in 12 mins"`). 
    - *Logic*: Calculated based on store load vs. active driver count.
- **Habit Strip**: Located directly below the search bar. A horizontal scroll of "Your Usuals" (Top 5 most frequently purchased SKUs).
- **Lifestyle Tags**: Rapid discovery chips (e.g., `[Vegan]`, `[Breakfast]`, `[Pet Care]`).
- **Dynamic Promo Banners**: High-impact horizontal carousel for curated deals.

### 1.2 Catalog & Grid (The Zero-Click Add)
- **Interactive Stepper**: 
    - *Default State*: A prominent `[ + ADD ]` button.
    - *Active State*: Transforms into `[ - 1 + ]` on first tap. No page transitions allowed for basic quantity adjustments.
- **Scarcity & Quality Labels**:
    - **Freshness**: `"Freshly Picked Today"` for produce/bakery.
    - **Stock**: `"Low Stock: Only {n} left"` (Triggers at < 5 units).
    - **Best Value**: Highlight `"Rp {price} / {unit}"` in **Wrap Emerald** for price-leader items.

### 1.3 Product Detail Page (The Trust Builder)
- **Temperature Indicator**: Critical for FMCG (e.g., `[ ❄️ Chilled ]` or `[ 🔥 Hot ]`).
- **Replacement Preferences**: 
    - *Label*: `"If out of stock:"`
    - *Options*: `[ Call me ]`, `[ Replace with similar ]`, `[ Refund ]`.
- **Direct Cart Toggle**: A sticky footer quantity selector that remains visible regardless of scroll depth.

### 1.4 Identity & Access (Frictionless Entry)
- **Email/Password Login**: Primary method with rounded text fields and clear error states.
- **Biometric Integration**: 
    - *Positioning*: Located on the **right side** of the primary "Login" button for ergonomic, high-speed access.
    - *Adaptive Icons*: Automatically switches between FaceID and TouchID glyphs based on device capability.
- **Social Auth (Google)**: 
    - Branded white button with "G" logo and grey border.
    - Located below an "OR" separator to distinguish from manual entry.
- **Privacy Compliance**: Custom usage descriptions provided for FaceID and Location permissions to build user trust and ensure App Store compliance.

---

## 🔄 2. User Flow

### 2.1 The Friction-Killer (Transactional Flow)
- **Address Micro-Details**: 
    - Mandatory: `Floor / Unit Number`.
    - Selector: `Drop-off Point` (`[ Hand to me ]`, `[ Leave at door ]`, `[ Lobby ]`).
- **No-Surprise Bill Summary**:
    - `Item Total`
    - `Promo Discount` (Green)
    - `Delivery Fee` (Show `$0.00` if free)
    - **Total Amount** (Boldest text)
    - *Note*: Packaging fees are explicitly removed to maintain brand trust.

### 2.2 The Anxiety Reducer (Post-Purchase)
- **Warehouse Milestones**: Status updates that increase perceived value (e.g., `"Rider is checking item quality..."`).
- **Live Chat Trigger**: Direct shortcut to the rider with pre-filled essential messages (e.g., `"The gate is open"`, `"Call me on arrival"`).

---

## 🏷 3. Labels & Dynamic Values

### 3.1 Order & Delivery States
| State | Label | UX Context |
| :--- | :--- | :--- |
| **Pending** | `RESERVING STOCK` | 15-minute window visualization. |
| **Paid** | `PREPARING` | Warehouse/Dark Store fulfillment. |
| **In Transit** | `ON THE WAY` | Live Map tracking active. |
| **Delivered** | `ARRIVED` | Haptic success trigger. |

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
