# VAYA – B2B Group Buying Platform
## Project Tracker

---

## 📋 Project Overview
B2B Group Buying Mobile App for the Indian market.  
Multiple businesses combine purchase orders to unlock bulk discounts.

**Platform:** Android (Phase 1) → Web (Phase 2) → Admin Panel (Phase 3)  
**Stack:** Flutter + Firebase (Firestore, Auth, Storage, FCM)  
**State Management:** Riverpod  
**Navigation:** GoRouter

---

## 🏗️ Architecture
```
lib/
  core/
    constants/        # app colors, strings, dimensions
    router/           # GoRouter config
    theme/            # app theme
    utils/            # helpers, formatters
  features/
    auth/             # OTP login, business profile setup
    home/             # product & deal listings
    products/         # product detail, pricing tiers
    groups/           # group creation, joining, progress, chatroom
    orders/           # order tracking, buyer dashboard
    supplier/         # supplier panel (HIDDEN - feature flagged)
    payments/         # token payment + final payment flow
  shared/
    models/           # data models
    widgets/          # reusable UI components
    providers/        # shared Riverpod providers
```

---

## ✅ Implementation Tasks

### Phase 0 – Project Setup
- [x] Create TRACKER.md
- [ ] Update pubspec.yaml with all dependencies
- [ ] Configure Firebase (placeholder config)
- [ ] Setup app theme, colors, typography
- [ ] Setup GoRouter navigation
- [ ] Setup Riverpod

### Phase 1 – Authentication
- [ ] Splash screen
- [ ] OTP Login screen (mobile number entry)
- [ ] OTP Verification screen
- [ ] Business Profile Setup screen (name, GST, category, address)
- [ ] Auth state management (Riverpod)
- [ ] Firebase Auth integration (phone OTP)

### Phase 2 – Home & Product Browsing
- [ ] Home screen (deal listings, categories)
- [ ] Product card widget
- [ ] Deal card widget (with countdown timer)
- [ ] Product detail screen
  - [ ] Pricing tiers display
  - [ ] Group progress bar
  - [ ] Join / Create group CTA
- [ ] Search & filter

### Phase 3 – Group Buying Core Logic ⭐ CRITICAL
- [ ] Group model (id, product, tiers, current qty, deadline, status, members)
- [ ] Pricing tier model (min_qty, price_per_unit)
- [ ] Dynamic price calculation based on total quantity
- [ ] Create group screen (set quantity, invite)
- [ ] Join group screen (select quantity)
- [ ] Group progress screen
  - [ ] Real-time quantity counter (Firestore streams)
  - [ ] Countdown timer
  - [ ] Current price tier display
  - [ ] Members list
- [ ] Two group modes:
  - [ ] Mode A: Buyers form group → request supplier discount
  - [ ] Mode B: Supplier sets target → buyers join to unlock
- [ ] Supplier confirmation flow for discount approval
- [ ] Group completion logic
- [ ] Group incompletion handling
  - [ ] Case 1: Buyer fails to pay → token amount enforcement → notification → redistribute
  - [ ] Case 2: Group not complete → join another group / fulfill leftover / extend time

### Phase 4 – Group Chatroom
- [ ] Chat screen per group
- [ ] Text messages
- [ ] Image sharing
- [ ] Video sharing
- [ ] Audio messages
- [ ] Firebase Storage for media
- [ ] Real-time Firestore chat listener

### Phase 5 – Payments
- [ ] Token payment screen (company QR / payment details shown)
- [ ] Pro forma invoice generation & display
- [ ] Final payment screen (seller QR + bank details shown)
- [ ] Payment status tracking
- [ ] Full payment flow
- [ ] Partial payment (optional - MVP placeholder)

### Phase 6 – Orders & Dashboard
- [ ] Buyer dashboard
  - [ ] Active groups
  - [ ] Order history
  - [ ] Payment status
- [ ] Order detail screen
- [ ] Order status tracking
- [ ] Notifications (FCM)
  - [ ] Deal expiry alerts
  - [ ] Group completion updates
  - [ ] Payment reminders

### Phase 7 – Supplier Panel (HIDDEN in MVP)
- [ ] Feature flag: `kSupplierPanelEnabled = false`
- [ ] Supplier login/signup
- [ ] Add/manage product listings
- [ ] Define pricing tiers
- [ ] Set group targets (Mode B)
- [ ] Confirm/approve discount requests
- [ ] View & manage bulk orders
- [ ] Update order status

---

## 🎨 Design System
- **Primary Color:** Deep Blue `#1A237E`
- **Accent Color:** Amber/Orange `#FF6F00`
- **Background:** `#F5F7FA`
- **Success:** `#2E7D32`
- **Error:** `#C62828`
- **Font:** Inter / Poppins
- **Style:** Professional, clean, B2B-focused

---

## 📦 Dependencies
| Package | Purpose |
|---------|---------|
| firebase_core | Firebase initialization |
| firebase_auth | Phone OTP authentication |
| cloud_firestore | Real-time database |
| firebase_storage | Media file storage |
| firebase_messaging | Push notifications |
| flutter_riverpod | State management |
| riverpod_annotation | Code generation for Riverpod |
| go_router | Navigation |
| cached_network_image | Image caching |
| intl | Date/number formatting (₹) |
| image_picker | Pick images/videos |
| file_picker | Pick files |
| just_audio | Audio playback |
| record | Audio recording |
| pinput | OTP input field |
| shimmer | Loading skeletons |
| lottie | Animations |
| share_plus | Share content |
| url_launcher | Open URLs |
| permission_handler | Runtime permissions |
| connectivity_plus | Network status |
| flutter_local_notifications | Local notifications |
| uuid | Generate unique IDs |
| timeago | Relative time display |
| percent_indicator | Progress bars |
| qr_flutter | QR code display |

---

## 🚀 Deployment Checklist
- [ ] Firebase project created & configured
- [ ] google-services.json added
- [ ] Android signing keystore configured
- [ ] Minimum SDK: Android 21 (5.0)
- [ ] Target SDK: Android 34
- [ ] App permissions declared in AndroidManifest
- [ ] ProGuard rules for Firebase
- [ ] Release build tested

---

## 📅 Milestones
| Milestone | Status |
|-----------|--------|
| Project Setup & Architecture | 🔄 In Progress |
| Auth Flow | ⏳ Pending |
| Home & Product Browsing | ⏳ Pending |
| Group Buying Core Logic | ⏳ Pending |
| Group Chatroom | ⏳ Pending |
| Payments | ⏳ Pending |
| Orders & Dashboard | ⏳ Pending |
| Supplier Panel (hidden) | ⏳ Pending |
| Android Build & Testing | ⏳ Pending |

---

*Last updated: Phase 0 – Project Setup*

---

## ✅ Implementation Status (Phase 0–7 Complete)

| Phase | Status |
|-------|--------|
| Phase 0 – Project Setup | ✅ Complete |
| Phase 1 – Authentication | ✅ Complete |
| Phase 2 – Home & Products | ✅ Complete |
| Phase 3 – Group Buying Core Logic | ✅ Complete |
| Phase 4 – Group Chatroom | ✅ Complete |
| Phase 5 – Payments | ✅ Complete |
| Phase 6 – Orders & Dashboard | ✅ Complete |
| Phase 7 – Supplier Panel (hidden) | ✅ Stubbed (feature-flagged off) |

### What's Built
- **34 Dart files** across clean architecture
- **PricingEngine** – core group buying logic with dynamic tier pricing
- **Real-time Firestore streams** for group quantity updates
- **Countdown timers** (inline + box widget)
- **Group progress bars** with tier visualization
- **Two group modes** (buyer-initiated + supplier-target)
- **Supplier discount approval flow**
- **Group chatroom** with image/audio/video support
- **Token payment** (company QR + bank details)
- **Final payment** (supplier QR + bank details)
- **Proforma invoice** screen
- **Order tracking** with visual stepper
- **Supplier panel** code present but hidden via `kSupplierPanelEnabled = false`

### Next Steps Before Running
1. Run `flutterfire configure` to set up Firebase
2. Download Poppins fonts → `assets/fonts/`
3. Uncomment fonts in `pubspec.yaml`
4. Add `google-services.json` to `android/app/`
5. Update payment details in `app_constants.dart`
6. Seed test products in Firestore
7. Run `flutter run`

*Last updated: MVP Implementation Complete*

---

## ✅ Session 3 – Completed

### Bug Fixes
- [x] OTP screen overflow when keyboard opens → replaced Column+Spacer with SingleChildScrollView
- [x] `resizeToAvoidBottomInset: true` on OTP Scaffold

### New Features
- [x] **FCM Push Notifications** – NotificationService with full setup:
  - Background message handler
  - Permission requests (Android + iOS)
  - 5 Android notification channels
  - Foreground message display via local notifications
  - Notification tap routing
  - FCM token saved to Firestore on login
  - Token refresh listener
- [x] **Product Search** – Full search screen with:
  - Real-time client-side filtering
  - Category filter chips
  - Tappable search bar on home screen navigates to search
  - Empty state + no results state
- [x] **Group Incompletion Handling**
  - Case 1 (buyer fails to pay): `removeMemberForNonPayment()` in GroupService
  - Case 2 (group not complete): `GroupExpiredScreen` with 4 options:
    - Join another active group for same product
    - Fulfill demand yourself (individual order)
    - Request time extension (creator only, max 2x)
    - Browse other products
  - Expired group detail screen navigates to options screen
- [x] **Cloud Functions** (functions/index.js):
  - `expireGroups` – scheduled every 15 min, marks expired groups + notifies members
  - `onGroupCompleted` – creates order docs for all members + notifies
  - `onOrderStatusChanged` – notifies buyer on status change
  - `onNewChatMessage` – notifies group members of new messages
  - `paymentReminders` – daily 9am IST reminder for pending token payments
- [x] **Firestore Security Rules** (firestore.rules)
- [x] **Storage Security Rules** (storage.rules)
- [x] **Firestore Indexes** (firestore.indexes.json) – 6 composite indexes
- [x] **firebase.json** – functions + firestore + storage + emulators config

### Deploy Cloud Functions
```bash
cd functions && npm install
firebase deploy --only functions,firestore:rules,firestore:indexes,storage
```

*Last updated: Session 3 – Notifications, Search, Incompletion Handling, Cloud Functions*

---

## ✅ Session 4 – Completed

### New Features
- [x] **Notifications Screen** – In-app notification list with:
  - Unread badge on home screen bell icon
  - Mark all read / mark single read
  - Tap to navigate to relevant screen via route
  - Type-based icons and colors (payment, order, group, chat, deal)
  - timeago relative timestamps
  - Pull-to-refresh
- [x] **Edit Profile Screen** – Full profile editing with:
  - Profile photo picker (gallery) + upload to Firebase Storage
  - Business name, GST, category, address, city, state, pincode
  - Firestore update + auth state refresh
- [x] **Payment Proof Upload Screen** – Full upload flow:
  - Camera or gallery source picker
  - Upload progress indicator
  - Notes field (transaction ID, reference)
  - Saves to Firebase Storage + Firestore payments collection
  - Auto-updates member payment status to token_paid
  - Wired into token payment screen "Upload Screenshot" button
- [x] **Connectivity Banner** – Animated offline banner at top of all screens
- [x] **Loading Skeletons** – Pulsing skeleton widgets:
  - `LoadingSkeleton` (generic)
  - `ProductCardSkeleton`
  - `GroupCardSkeleton`
  - `SkeletonList`
- [x] **Notification Badge** – Unread count badge on home screen bell
- [x] **Notification Provider** – Firestore stream + unread count + mark read helpers

### Wiring
- [x] Profile screen → Edit Profile (navigates to /edit-profile)
- [x] Profile screen → Notifications (navigates to /notifications)
- [x] Home bell → Notifications with live unread badge
- [x] Token payment → Upload proof (navigates to /payment/proof/:groupId/token)
- [x] ConnectivityBanner wraps entire app via MaterialApp.router builder

### All Routes
| Route | Screen |
|-------|--------|
| `/` | Splash |
| `/login` | Login (OTP entry) |
| `/otp` | OTP Verify |
| `/business-profile` | Business Profile Setup |
| `/home` | Home (bottom nav) |
| `/search` | Product Search |
| `/product/:id` | Product Detail |
| `/create-group/:productId` | Create Group |
| `/group/:id` | Group Detail |
| `/join-group/:id` | Join Group |
| `/group-chat/:id` | Group Chat |
| `/group-expired/:id` | Group Expired Options |
| `/orders` | Orders List |
| `/order/:id` | Order Detail |
| `/payment/token/:groupId` | Token Payment |
| `/payment/final/:orderId` | Final Payment |
| `/payment/proof/:groupId/:type` | Upload Payment Proof |
| `/invoice/:orderId` | Proforma Invoice |
| `/notifications` | Notifications |
| `/profile` | Profile |
| `/edit-profile` | Edit Profile |

*Last updated: Session 4 – Notifications, Edit Profile, Payment Proof Upload, Skeletons, Connectivity*
