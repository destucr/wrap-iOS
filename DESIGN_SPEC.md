# Wrap iOS UI/UX Design Specification
**Role**: Senior UI/UX Designer  
**Context**: Indonesian Q-Commerce (Precision Logistics)  
**Philosophy**: "Dense but Clear" — Optimized for high-frequency Indonesian shoppers.

---

## 📱 SCREEN 1 — Product Detail Page (PDP)
**Primary Goal**: Foster confidence through technical transparency and facilitate immediate purchase.

### Layout Hierarchy (Top to Bottom)
1.  **Product Imagery**: Full-width aspect-ratio (1:1) gallery. Supports edge-to-edge swiping.
2.  **Price Block**: 
    *   **Main Price**: Giant, bold Wrap Emerald text. The most visually dominant element after the image.
    *   **Original Price**: Strikethrough grey text with a high-contrast discount percentage badge (e.g., `50% OFF`).
3.  **Product Identity**: Name in Header weight, followed by an inline metadata row.
4.  **Metadata Row (Technical Specs)**: 
    *   `Berat`: Essential for Indonesian logistics (e.g., 85g).
    *   `Stok`: Shows quantity. Triggers **Urgency Mode** (Red text/Icon) when stock < 5.
    *   `Rating`: 5-star visual with numerical count.
5.  **Description**: Collapsible text block. Default shows 3 lines with a "Lihat Selengkapnya" trigger.
6.  **Quantity Selector (Jumlah)**: A horizontal control with labeled plus/minus buttons. 
7.  **Recommendations**: Horizontal "Carousel" scroll. Tapping replaces the PDP context with a smooth transition.

### Component Behavior & Interactions
*   **Sticky Bottom Bar**: 
    *   **Left**: Shopping cart icon button (Secondary CTA) for background accumulation.
    *   **Right**: `[ Beli Sekarang ]` high-weight button (Primary CTA) for immediate checkout.
*   **Add-to-Cart Success**: A non-blocking snackbar (Toast) appears at the top: *"Berhasil ditambahkan!"* with a `[ Lihat Keranjang ]` shortcut. The user remains on the PDP to continue browsing recommendations.

### Design Rationale
*   **Tokopedia-Style Density**: Indonesian users prefer seeing technical specs (Berat, Stok) immediately without digging into descriptions.
*   **Immediate Action**: By placing the quantity selector *above* the recommendation grid, we ensure the user "commits" to a volume before being distracted by other products.

---

## 🛍️ SCREEN 2 — Review Order
**Primary Goal**: Absolute transparency to eliminate "Checkout Abandonment."

### Layout Hierarchy (Top to Bottom)
1.  **Delivery Address Block**: 
    *   Icon-anchored header: "Alamat Pengiriman."
    *   Content: Recipient Name, Phone, and Full Address snippet.
    *   Action: `[ Ganti ]` button on the far right to trigger the Address Picker.
2.  **Order Items**:
    *   List of product cards. Each card includes an inline stepper.
    *   Decreasing to zero triggers a haptic warning and a simple *"Hapus barang?"* confirmation.
3.  **Pricing Breakdown (The Transparency Card)**:
    *   `Total Harga Barang`: Sum of all items.
    *   `Ongkos Kirim`: Fixed or distance-based logistics fee.
    *   `Biaya Layanan`: Fixed platform fee.
    *   `Promo/Voucher`: (Placeholder) Highlighted in green if applied.
4.  **Sticky Action Bar**:
    *   **Left**: `Total Pembayaran` summary.
    *   **Right**: `[ Bayar Sekarang ]` primary button.

### Component Behavior & Interactions
*   **Real-time Recalculation**: Any change in the item stepper immediately updates the `Total Harga Barang` and `Total Pembayaran` with a subtle fade animation on the numbers.
*   **Address Anchoring**: Placing the address at the absolute top builds trust—the user knows exactly *where* the goods are going before they look at the *price*.

### Design Rationale
*   **Confidence Building**: Every fee is itemized. No "Hidden Fees" at the final step.
*   **Control**: Allowing quantity edits on the final review screen prevents the user from "Backing out" to the cart, keeping them in the conversion funnel.

---

## 👤 SCREEN 3 — Profile & Settings
**Primary Goal**: Efficient account management and security configuration.

### Layout Hierarchy (Top to Bottom)
1.  **Identity Header**: Large typography header with the User's name and primary contact method.
2.  **Grouped Settings (Inset Grouped Style)**:
    *   **Section: Informasi Akun**: Navigation to "Detail Akun" for Name, Phone, and Email edits.
    *   **Section: Keamanan**:
        *   `Biometric Login`: Toggle switch (FaceID/TouchID).
        *   `Pin Settings`: Navigation for secure PIN management.
    *   **Section: Logistik**: "Alamat Tersimpan" for multi-address management.
3.  **Logout**: Destructive red text button at the bottom of the list.

### Design Rationale
*   **Familiarity**: Uses the native iOS `insetGrouped` table style to feel like a system-level setting, increasing the user's sense of security.
*   **Ergonomics**: Frequently used security toggles are placed in the upper half of the list for easy thumb access.
