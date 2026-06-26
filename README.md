# Expense Mate

A production-ready **Expense Tracker & Personal Finance** app built with Flutter. Track income, expenses, budgets, savings, and goals — online or offline — with automatic Firebase sync.

![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart)
![Firebase](https://img.shields.io/badge/Firebase-Backend-FFCA28?logo=firebase)
![License](https://img.shields.io/badge/License-Private-lightgrey)

---

## Features

### Available (Phase 1)
- **Authentication** — Email/password, Google Sign-In, Apple Sign-In
- **Onboarding** — First-launch walkthrough
- **Dashboard shell** — Balance overview, summary cards, quick actions
- **Offline-first database** — Drift (SQLite) with sync queue
- **Sync engine** — Auto-sync to Firestore when back online
- **Material 3 UI** — Light/dark theme, shimmer loading, error & empty states
- **Firestore security rules** — User-scoped data access

### Planned
- Transactions CRUD (income, expense, transfer, recurring)
- Wallets, categories, budgets, savings & goals
- Reports & charts (pie, bar, line, area)
- Bills, notifications & reminders
- Settings — currency, language, PIN/biometric lock, PDF/CSV export

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter, Material Design 3 |
| Architecture | Clean Architecture, Feature-First, MVVM |
| State Management | Riverpod |
| Routing | GoRouter |
| Backend | Firebase Auth, Firestore, Storage, FCM, Analytics, Crashlytics, Remote Config, App Check |
| Offline DB | Drift (SQLite) |
| Serialization | Freezed, Json Serializable |
| Charts | fl_chart |
| Networking | Dio |

---

## Architecture

```
lib/
├── core/                    # Shared infrastructure
│   ├── constants/           # App, Firestore, enums
│   ├── theme/               # Material 3 themes
│   ├── errors/              # Failures, Result type
│   ├── network/             # Dio, connectivity
│   ├── database/            # Drift tables & DAOs
│   ├── services/            # Firebase, sync, storage
│   ├── widgets/             # Reusable UI components
│   ├── routes/              # GoRouter config
│   ├── extensions/          # Dart extensions
│   └── utils/               # Validators, formatters
│
└── features/                # Feature modules
    └── authentication/
        ├── data/            # Data sources, models, repo impl
        ├── domain/          # Entities, repo contracts, use cases
        └── presentation/    # Pages, providers, widgets
```

Each feature follows **Clean Architecture**:

```
Presentation → Domain (Use Cases) → Data (Repository) → Firebase / SQLite
```

Offline writes go to SQLite first, are marked `pending`, and sync to Firestore when connectivity returns. Conflicts resolve using the latest `updatedAt` timestamp.

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.41+ stable)
- [Dart SDK](https://dart.dev/get-dart) (3.11+)
- Android Studio / Xcode (for device builds)
- A [Firebase project](https://console.firebase.google.com/)

---

## Getting Started

### 1. Clone & install dependencies

```bash
git clone <your-repo-url>
cd expense_mate
flutter pub get
```

### 2. Firebase setup

1. Create a project in [Firebase Console](https://console.firebase.google.com/) (or use existing `expense-mate-af37a`).
2. Enable **Authentication** providers:
   - Email/Password
   - Google
   - Apple (iOS)
3. Create a **Cloud Firestore** database.
4. Android config is included (`android/app/google-services.json`).
5. For iOS, download `GoogleService-Info.plist` and add it to `ios/Runner/`, then update `lib/firebase_options.dart` with the correct iOS `appId`.

### 3. Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```

Rules live in [`firestore.rules`](firestore.rules) — users can only read/write their own documents.

### 4. Generate code (Drift)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 5. Run the app

```bash
flutter run
```

**Build Android APK:**

```bash
flutter build apk --debug
```

---

## Testing

```bash
# All tests
flutter test

# Analyzer
flutter analyze
```

---

## Firestore Collections

| Collection | Description |
|------------|-------------|
| `users` | User profiles |
| `wallets` | Cash, bank, cards, digital wallets |
| `transactions` | Income, expense, transfer records |
| `categories` | Income & expense categories |
| `budgets` | Daily/weekly/monthly/yearly limits |
| `goals` | Savings goals |
| `savings` | Savings entries |
| `bills` | Recurring bills |
| `notifications` | In-app notifications |
| `settings` | User preferences |
| `receipts` | Receipt metadata |

---

## Development Roadmap

| Phase | Scope | Status |
|-------|--------|--------|
| 1 | Foundation, auth, core UI, Drift DB, sync engine | Done |
| 2 | Transactions, wallets, categories | Done |
| 3 | Dashboard with real data & charts | Done |
| 4 | Budgets, savings, goals | Done |
| 5 | Bills, notifications | Done |
| 6 | Settings, profile, security | Done |
| 7 | Export PDF/CSV, backup/restore | Done |

---

## Project Info

- **App ID (Android):** `com.nurujjaman.expense_mate`
- **Min SDK:** 23
- **Version:** 1.0.0+1

---

## License

Private project — not published to pub.dev.
