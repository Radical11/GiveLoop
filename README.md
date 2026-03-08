# GiveLoop — Flutter Mobile App

**GiveLoop** is a mobile-first charity donation platform connecting donors with verified NGOs. Built with **Flutter** and **Provider** state management, it consumes the GiveLoop Django backend API with beautiful animations, real-time filtering, and gamified donation tracking.

***

## 🚀 Features

| Feature | Description |
| --- | --- |
| **Beautiful UI** | Gradient cards, smooth animations, Material 3 design |
| **Real-time Filtering** | Tap category icons (clothes, food, medicine) to filter NGOs |
| **NGO Cards** | Image-first cards with progress bars, distance, pledge status |
| **Auth Integration** | JWT login/register with username display & logout → login flow |
| **Category Icons** | Visual icons for clothes, food, medicine, books, toys, electronics |
| **Responsive Layout** | SafeArea, gradient backgrounds, horizontal scrolling lists |
| **Drawer Menu** | Profile info with actual username + logout navigation |
| **Error Handling** | Loading states, empty states, retry buttons, offline fallbacks |
| **Navigation** | Deep linking to `DetailsScreen` from NGO cards |

***

## 📱 Screens & Widgets

```
lib/
├── main.dart
├── home_screen.dart       # Main screen with filtering & NGO lists
├── login_screen.dart      # JWT login/register
├── signup_screen.dart
├── signin_screen.dart
├── details_screen.dart    # NGO details & pledge button
│   └── pledge_screen.dart # Welcome flow (TODO)
├── api_service.dart       # HTTP client for backend API
├── providers/
│   └── needs_provider.dart    # NGO needs with fetch & filtering
├── models/
│   └── ngo_model.dart         # NGO data model
├── services/
│   └── auth_provider.dart     # JWT auth with username storage
└── config/
    └── app_config.dart          # Reusable NGO card widget
```

***

## 🎨 Key UI Components

### Home Screen Layout
```
┌─────────────────────────────┐
│ [☰]          [🔔] [👤]      │ ← Top bar w/ drawer
├─────────────────────────────┤
│ Good Morning, User!         │
│ [Search: What to donate?]   │
│ [View Leaderboard →]        │
│                             │
│ 🏪 NGOs With Urgent Need    │ ← Horizontal scroll
│ [NGO Card][NGO Card]...     │
│                             │
│ 📍 NGOs Near You (5 NGOs)   │ ← Filtered vertical list
│ [Clothes👕][Food🍽️]...     │ ← Category filter chips
│ [NGO Card]                  │
│ [NGO Card]                  │
└─────────────────────────────┘
```

### Category Filter Icons
```
👕 Clothes: Icons.checkroom
🍽️ Food:    Icons.restaurant  
🩺 Health:  Icons.health_and_safety
📚 Books:   Icons.menu_book
🧸 Toys:    Icons.toys
📱 Electronics: Icons.devices
```

***

## 🛠️ Setup

### Prerequisites
- Flutter 3.10+
- Dart 3.0+
- Android Studio / Xcode
- GiveLoop Backend API running

### Installation

```bash
# Clone repository
git clone https://github.com/Radical11/GiveLoop.git
cd GiveLoop/frontend  # or wherever Flutter lives

# Flutter setup
flutter pub get
flutter clean

# Run on device/emulator
flutter run
```

### Backend Connection
Update `api_service.dart` with your backend URL:
```dart
const String baseUrl = 'http://your-backend-url.com/api/';
```

***

## 🔄 State Management Flow

```
LoginScreen → AuthProvider.login()
     ↓
HomeScreen → NeedsProvider.fetchNeeds()
     ↓ (Category Tap)
_selectedCategory → _buildNearbyNgos() filter
     ↓ (Logout)
AuthProvider.logout() → LoginScreen (pushReplacement)
```

***

## 🎮 Current Features Live

✅ **Category Filtering** - Click clothes icon → see only clothes NGOs  
✅ **Drawer w/ Logout** - Three-line menu → username + logout → login screen  
✅ **Username Display** - Shows actual username from JWT response  
✅ **Progress Bars** - Visual pledge progress (`qtyPledged/qtyNeeded`)  
✅ **Distance Display** - "2.3 km away" style proximity  
✅ **Error States** - Loading, empty, retry flows  
✅ **Responsive** - SafeArea, horizontal/vertical scroll handling  

***

## 🚧 TODO Features

- [ ] **DetailsScreen** - Pledge button + quantity selector
- [ ] **LeaderboardScreen** - Top donors by GiveCoins
- [ ] **ProfileScreen** - Donation history, badges, GiveCoins balance
- [ ] **Search** - Real-time NGO search
- [ ] **Push Notifications** - Pledge confirmations & need completions
- [ ] **WebSocket Updates** - Live progress bar animations
- [ ] **Onboarding** - Welcome tour for first-time users

***

## 📱 Supported Platforms

| Platform | Status |
| --- | --- |
| **Android** | ✅ Ready |
| **iOS** | ✅ Ready (Test on device) |
| **Web** | 🔄 Responsive (needs API CORS) |

***

## 🔐 Demo Usage

1. **Login** with backend demo credentials:
   - `alice_donor` / `giveloop2026`
2. **Filter** by clicking category icons (👕 clothes, etc.)
3. **Tap** NGO cards → DetailsScreen
4. **Logout** from drawer (☰) or profile icon

***

## 📄 License

MIT License - Built for social good!

***

**⭐ Star on GitHub if you find it helpful!**