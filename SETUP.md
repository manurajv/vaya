# VAYA – Setup Guide

## Prerequisites
- Flutter SDK 3.10+
- Android Studio / VS Code
- Firebase account
- Node.js (for Firebase CLI)

---

## Step 1: Firebase Setup

### 1.1 Create Firebase Project
1. Go to https://console.firebase.google.com
2. Create a new project named `vaya-app`
3. Enable Google Analytics (optional)

### 1.2 Enable Firebase Services
In Firebase Console, enable:
- **Authentication** → Phone (enable Phone sign-in)
- **Firestore Database** → Create in production mode
- **Storage** → Create default bucket
- **Cloud Messaging** → Already enabled by default

### 1.3 Configure FlutterFire
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (run from project root)
flutterfire configure --project=your-firebase-project-id
```
This auto-generates `lib/firebase_options.dart`.

### 1.4 Update main.dart
Uncomment the options line in `lib/main.dart`:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

---

## Step 2: Android Configuration

### 2.1 Add google-services.json
- Download from Firebase Console → Project Settings → Android app
- Place at: `android/app/google-services.json`

### 2.2 Update android/app/build.gradle.kts
Add at the bottom:
```kotlin
apply(plugin = "com.google.gms.google-services")
```

### 2.3 Update android/build.gradle.kts
Add to dependencies:
```kotlin
classpath("com.google.gms:google-services:4.4.0")
```

### 2.4 AndroidManifest.xml Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

---

## Step 3: Fonts Setup

Download Poppins from Google Fonts:
https://fonts.google.com/specimen/Poppins

Place these files in `assets/fonts/`:
- `Poppins-Regular.ttf`
- `Poppins-Medium.ttf`
- `Poppins-SemiBold.ttf`
- `Poppins-Bold.ttf`

---

## Step 4: Install Dependencies

```bash
flutter pub get
```

---

## Step 5: Firestore Security Rules

In Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Products are readable by all authenticated users
    match /products/{productId} {
      allow read: if request.auth != null;
      allow write: if false; // Only via admin/supplier panel
    }
    
    // Groups
    match /groups/{groupId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Orders
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (resource.data.buyerId == request.auth.uid || 
         resource.data.supplierId == request.auth.uid);
      allow create: if request.auth != null;
      allow update: if request.auth != null;
    }
    
    // Chat messages
    match /chats/{groupId}/messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Step 6: Firebase Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.resource.size < 50 * 1024 * 1024;
    }
  }
}
```

---

## Step 7: Run the App

```bash
# Debug mode
flutter run

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

---

## Step 8: Seed Test Data

Use Firebase Console or a seed script to add test products with pricing tiers.

Example product document in Firestore (`products` collection):
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

## Company Payment Details
Update `lib/core/constants/app_constants.dart` with actual values:
- `companyUpiId` – Your company UPI ID
- `companyAccountName` – Company name
- `companyBankName` – Bank name
- `companyAccountNumber` – Account number
- `companyIfscCode` – IFSC code
