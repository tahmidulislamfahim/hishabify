# 📒 Hishabify - Digital Khata & Business Ledger Book

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green" alt="Platform" />
  <img src="https://img.shields.io/badge/Database-SQLite-003B57?logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline-brightgreen" alt="Offline & Private" />
  <img src="https://img.shields.io/badge/License-MIT-orange" alt="License" />
</p>

<p align="center">
  <strong>Hishabify</strong> is a secure, modern, and offline-first digital ledger & credit book app designed for small businesses, shopkeepers, retailers, freelancers, and personal bookkeeping. Replace your paper khata / ledger register with a sleek digital experience that tracks customer dues, credits (Udhar), and payments (Jama) effortlessly.
</p>

---

## ✨ Key Features

- **📒 Customer Ledger & Khata**:
  - Track customer dues, advances, credit (*Udhar*), and payments (*Jama*).
  - Instant net balance calculations with color-coded status badges (Due vs. Advance).
  - Search, sort by balance or name, and filter customer records seamlessly.

- **🏢 Multi-Profile Management**:
  - Separate profiles for multiple businesses, stores, or personal daily expenses.
  - Switch between profiles instantly with dedicated currencies per profile.

- **📊 Professional Report Export**:
  - Export professional **PDF Statements** formatted for printing and sharing.
  - Export structured **Excel (.xlsx)** spreadsheets for external accounting and audits.
  - Filter reports by customer, transaction type, or custom date ranges (Today, This Month, Custom).

- **🔒 Biometric & System App Lock**:
  - Secure your financial records with fingerprint authentication or device PIN / Pattern.
  - Graceful fallback for devices without hardware biometrics.

- **💱 Multi-Currency Support**:
  - Native currency support including BDT (৳), INR (₹), USD ($), EUR (€), GBP (£), SAR, AED, PKR, CAD, AUD, and more.
  - Automatic synchronization between active business profiles and app settings.

- **💾 Local Backup & Restore**:
  - One-tap secure JSON backup export to local storage or cloud drive.
  - Hassle-free restore functionality with zero data lock-in.

- **📇 Phone Contacts Integration**:
  - Quickly import customer names and phone numbers directly from your address book.

- **🛡️ 100% Offline & Private**:
  - Your financial data never leaves your device. No analytics, no ads, and no external tracking servers.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management**: [Riverpod](https://riverpod.dev) (`flutter_riverpod`)
- **Local Persistence**: [SQLite](https://pub.dev/packages/sqflite) (`sqflite` + `path`)
- **Security**: [Local Auth](https://pub.dev/packages/local_auth) (Biometrics & Screen Lock)
- **Reporting & Documents**:
  - PDF Generation & Printing: [`pdf`](https://pub.dev/packages/pdf), [`printing`](https://pub.dev/packages/printing)
  - Excel Spreadsheets: [`excel`](https://pub.dev/packages/excel)
- **Design System**: Material 3 with tailored rich teal palette, modern typography, and responsive cards.

---

## 📂 Project Structure

```text
lib/
├── app.dart                   # Root MaterialApp with theme & routing
├── main.dart                  # App entrypoint & SQLite initialization
├── core/
│   ├── database/              # SQLite schema, migrations & backup serializer
│   ├── security/              # Biometric & screen lock service (AppLockService)
│   ├── theme/                 # AppColors, typography & Material 3 ThemeData
│   └── utils/                 # Formatters, dialogs & helper utilities
└── features/
    ├── customer/              # Customer list, details, profile cards & models
    ├── filter/                # Advanced date & type transaction filters
    ├── onboarding/            # First-launch disclosure & privacy acceptance
    ├── profile/               # Multi-profile creation, switching & viewmodels
    ├── reports/               # PDF & Excel report engines, exported report view
    ├── settings/              # Settings management, local backup & app lock
    └── transaction/           # Credit/Debit transactions, ledger view & forms
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.0` or later)
- Android Studio / VS Code with Flutter extension
- Android SDK (API 34 recommended) or Xcode for iOS

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/hishabify.git
   cd hishabify
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run in development mode**:
   ```bash
   flutter run
   ```

4. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```
   The built APK will be available at:
   `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔐 Required Permissions

| Permission | Purpose |
| :--- | :--- |
| `READ_CONTACTS` | Optional import of customer names and phone numbers directly from phone book. |
| `USE_BIOMETRIC` / `USE_FINGERPRINT` | Optional security lock using device fingerprint or screen lock PIN/Pattern. |
| `READ/WRITE_EXTERNAL_STORAGE` | Optional saving and sharing of exported PDF statements and Excel files. |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
