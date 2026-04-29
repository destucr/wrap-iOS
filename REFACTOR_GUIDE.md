# Wrap iOS Refactor Guide & Context

This document tracks major architectural changes to the Wrap iOS project to ensure revertability and context for future developers.

---

## 🛠 Phase 1: Service Layer (Network Abstraction)
**Status:** ✅ Completed  
**Reasoning:** Decouple ViewControllers and Managers from the technical details of `NetworkManager`. This centralized approach makes the code more testable and prevents duplication of endpoint strings and payload logic.

### Key Changes
- **`CatalogService.swift`**: Handles home feed, product listing, search, and details.
- **`CheckoutService.swift`**: Handles checkout previews and placing orders.
- **`UserService.swift`**: Handles profile fetching, synchronization, and authentication status.

### Before & After (Example)
**Before (in ViewController):**
```swift
let products: [Product] = try await NetworkManager.shared.request(endpoint: "/catalog/products")
```

**After (in ViewController):**
```swift
let products = try await CatalogService.shared.fetchProducts()
```

### How to Revert
If a specific network feature breaks:
1. Identify the service being called (e.g., `CatalogService`).
2. Verify the endpoint string and parameters inside the service against the old `NetworkManager` call.
3. If necessary, revert the call site in the ViewController to use `NetworkManager.shared.request` directly.

---

## 🛠 Phase 2: Coordinator Decomposition
**Status:** Planned  

---

## 🛠 Phase 3: Home VC Cleanup
**Status:** Planned
