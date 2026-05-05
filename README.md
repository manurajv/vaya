# VAYA – B2B Group Buying Platform

**India's First B2B Group Buying Mobile Application**

Buy Together, Save Together.

---

## 🚀 Project Status

✅ **MVP Implementation Complete** – All core features built and ready for Firebase setup.

- **34 Dart files** implementing clean architecture
- **Zero compile errors** – all code passes `flutter analyze`
- **8 unit tests passing** – PricingEngine logic validated
- **Android-first** – iOS support ready, web scaffolded

---

## 📱 Features

### ✅ Implemented
- **Phone OTP Authentication** (Firebase Auth)
- **Business Profile Setup** (GST, category, address)
- **Product Browsing** with pricing tiers
- **Group Buying Core Logic** ⭐
  - Dynamic tier pricing based on total quantity
  - Real-time Firestore streams for group updates
  - Countdown timers (inline + box widget)
  - Two modes: Buyer-initiated & Supplier-target
  - Supplier discount approval flow
- **Group Chatroom** (text + image, audio/video UI ready)
- **Token Payment** (company QR + bank details)
- **Final Payment** (supplier QR + bank details)
- **Proforma Invoice** generation
- **Order Tracking** with visual stepper
- **Supplier Panel** (code present, feature-flagged off)

### 🔜 Pending
- Firebase project configuration
- Push notifications (FCM)
- Audio recording in chat (removed temporarily due to upstream package conflict)
- Search & filter (UI placeholder ready)

---

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.10+ |
| **State Management** | Riverpod 2.6 |
| **Navigation** | GoRouter 14.8 |
| **Backend** | Firebase (Auth, Firestore, Storage, Messaging) |
| **Architecture** | Clean Architecture (features → data/domain/presentation) |
| **Testing** | flutter_test |

---

## 📦 Setup Instructions

### Prerequisites
- Flutter SDK 3.10+
- Android Studio / VS Code
- Firebase account
- Node.js (for FlutterFire CLI)

### Quick Start

```bash
# 1. Clone and install dependencies
git clone <repo-url>
cd vaya
flutter pub get

# 2. Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure --project=your-firebase-project-id

# 3. Download Poppins fonts
# Visit: https://fonts.google.com/specimen/Poppins
# Place in assets/fonts/ then uncomment fonts section in pubspec.yaml

# 4. Add google-services.json
# Download from Firebase Console → Project Settings → Android app
# Place at: android/app/google-services.json

# 5. Update payment details
# Edit lib/core/constants/app_constants.dart with your company UPI/bank details

# 6. Run the app
flutter run
```

**Detailed setup:** See [SETUP.md](SETUP.md)

---

## 📂 Project Structure

```
lib/
├── core/
│   ├── constants/       # Colors, strings, app config
│   ├── router/          # GoRouter navigation
│   ├── theme/           # Material theme
│   └── utils/           # Formatters, validators
├── features/
│   ├── auth/            # OTP login, business profile
│   ├── home/            # Product listings, deals
│   ├── products/        # Product detail, pricing tiers
│   ├── groups/          # Group creation, joining, chat
│   ├── orders/          # Order tracking, dashboard
│   ├── payments/        # Token + final payment
│   └── supplier/        # Supplier panel (hidden)
└── shared/
    ├── models/          # Data models (User, Product, Group, Order)
    └── widgets/         # Reusable UI components
```

---

## 🎯 Core Logic: PricingEngine

The heart of the group buying logic:

```dart
// Get active tier based on total quantity
final tier = PricingEngine.getActiveTier(tiers, totalQuantity);

// Calculate progress to next tier
final progress = PricingEngine.progressToNextTier(tiers, totalQuantity);

// Units needed to unlock next tier
final unitsNeeded = PricingEngine.unitsToNextTier(tiers, totalQuantity);
```

**All 8 unit tests pass** – run `flutter test`

---

## 🔐 Firebase Setup

### Required Services
- **Authentication** → Phone (OTP)
- **Firestore Database** → Real-time group data
- **Storage** → Chat media (images, videos)
- **Cloud Messaging** → Push notifications

### Security Rules
See [SETUP.md](SETUP.md) for Firestore and Storage security rules.

---

## 📊 Seed Data

Example product document for Firestore (`products` collection):

```json
{
  "supplierId": "supplier_001",
  "supplierName": "ABC Traders",
  "name": "Premium Basmati Rice",
  "description": "High quality basmati rice, 25kg bags",
  "category": "Food & Beverages",
  "imageUrls": [],
  "pricingTiers": [
    {"minQuantity": 100, "pricePerUnit": 1200, "label": "Bronze"},
    {"minQuantity": 500, "pricePerUnit": 1100, "label": "Silver"},
    {"minQuantity": 1000, "pricePerUnit": 1000, "label": "Gold"}
  ],
  "minimumOrderQuantity": 100,
  "unit": "bags",
  "specifications": {
    "Weight": "25 kg per bag",
    "Variety": "Basmati",
    "Origin": "Punjab"
  },
  "isActive": true,
  "basePrice": 1300,
  "location": "Delhi",
  "createdAt": "SERVER_TIMESTAMP",
  "updatedAt": "SERVER_TIMESTAMP"
}
```

---

## 🚧 Known Issues

1. **Audio recording removed temporarily** – `record` package has upstream conflict (`record_linux` 0.7.2 incompatible with `record_platform_interface` 1.5.0). Will re-add when `record` ^6.x is stable.

2. **Fonts not bundled** – Download Poppins from Google Fonts and place in `assets/fonts/`, then uncomment fonts section in `pubspec.yaml`.

3. **Firebase placeholder config** – Run `flutterfire configure` to replace placeholder values in `lib/firebase_options.dart`.

---

## 📝 Development Roadmap

### Phase 1 (Current – MVP)
- [x] Core group buying logic
- [x] Authentication & profiles
- [x] Product browsing
- [x] Group creation & joining
- [x] Chat (text + images)
- [x] Payment flows
- [x] Order tracking

### Phase 2 (Post-MVP)
- [ ] Push notifications (FCM)
- [ ] Search & filter
- [ ] Audio/video in chat
- [ ] Supplier panel (enable feature flag)
- [ ] Admin dashboard

### Phase 3 (Future)
- [ ] Automatic grouping
- [ ] Credit system
- [ ] Advanced logistics
- [ ] AI recommendations

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

---

## 📄 License

Proprietary – All rights reserved.

---

## 👥 Team

**Mavixas Technologies**

For support: support@vaya.in

---

## 📚 Documentation

- [SETUP.md](SETUP.md) – Detailed setup instructions
- [TRACKER.md](TRACKER.md) – Implementation progress tracker
- [assets/fonts/README.md](assets/fonts/README.md) – Font installation guide

---

**Built with ❤️ for India's B2B ecosystem**
