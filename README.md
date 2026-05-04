# Short Mining iOS Controller

A native iOS app (SwiftUI) that mirrors the functionality of the [Short-Mining-Android-Controller](https://github.com/harwinds13/Short-Mining-Android-Controller).

---

## 🚀 Setup

1. Clone the repo
2. Open `ShortMining.xcodeproj` in Xcode 15+
3. Xcode will automatically resolve Firebase via SPM (requires internet)
4. Replace `GoogleService-Info.plist` with the real one from Firebase Console → Project Settings → Your iOS app
5. Set your signing team in project settings (Signing & Capabilities → Team)
6. Build & Run

---

## 🔥 Firebase Setup

### Step 1 — Create Firebase iOS App
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Add an iOS app with **Bundle ID**: `com.harry.shortmining`
4. Download `GoogleService-Info.plist`

### Step 2 — Drop in the plist
Replace the placeholder `GoogleService-Info.plist` in the project root with the real file downloaded from Firebase Console.

### Step 3 — Enable Services
In the Firebase Console, enable:
- **Authentication** → Email/Password sign-in method
- **Firestore Database** → Create database in production mode

---

## 🏗 Project Structure

```
ShortMiningApp.swift          ← @main App entry point, configures Firebase
GoogleService-Info.plist      ← Firebase config (replace with real file!)
Info.plist                    ← App metadata + NSCameraUsageDescription

Models/
  Client.swift                ← Client data model
  ATOZEmployee.swift          ← ATOZ employee data model
  AdviceLog.swift             ← Service log entry model
  AdviceLogLevel.swift        ← Log level enum (info/error/warning/other)

Services/
  FirestoreService.swift      ← Singleton Firestore CRUD operations
  APIService.swift            ← REST API client for hiring.amazon.ca

ViewModels/
  AuthViewModel.swift         ← Login, register, sign-out, status listener
  PortalViewModel.swift       ← Vendor profile, service logs, real-time feed
  ClientListViewModel.swift   ← Client list with filter/search/status counts
  ATOZViewModel.swift         ← ATOZ employee list + save/logout

Views/
  Auth/
    LoginView.swift           ← Email/password login screen
    RegisterView.swift        ← Registration form
  Portal/
    PortalView.swift          ← Main dashboard after login
    AdviceLogRowView.swift    ← Single log row with level badge
  Clients/
    ClientListView.swift      ← 2-column grid of client cards
    ClientCardView.swift      ← Individual client card with context menu
    StatusBarView.swift       ← Coloured status count bar at top
  WebView/
    WebViewScreen.swift       ← WKWebView + localStorage injection + PIN capture
  ATOZ/
    ATOZClientView.swift      ← ATOZ employee grid + edit sheet
    ATOZEmployeeCard.swift    ← Individual ATOZ employee card
  Forms/
    ClientFormView.swift      ← Client detail editor + cascading job picker
    CandidateFormView.swift   ← Candidate personal data form
```

---

## 📱 Screen-by-Screen Feature Map

| Screen | Description |
|--------|-------------|
| **LoginView** | Email + password sign-in via Firebase Auth. Checks `users/{uid}.status == "active"` before allowing entry. Shows error if inactive. |
| **RegisterView** | Registration with name, email, phone, password validation (≥6 chars). Creates Firestore doc with `status: inactive`. |
| **PortalView** | Main dashboard. Shows vendor profile, 5 action buttons (Enable Service, Client List, Archived, ATOZ, Dummy). Real-time service logs feed with sound alert on new INFO log. Screen stays on (`isIdleTimerDisabled`). |
| **ClientListView** | 2-column LazyVGrid of clients. Supports search, filter by status, shows coloured status bar. Fetches from `client_sheet_2026` or `_archived`. |
| **ClientCardView** | Card coloured by status. Shows name, email (with copy), phone, location, job type, status badge, expire time. Context menu: Open Form, Mark as Done/Undone, Auto Re-Login toggle. Tap to open WebView. |
| **WebViewScreen** | Embedded `WKWebView` for `hiring.amazon.ca`. Injects localStorage tokens from `fullLocal`. Captures PIN via JS bridge. "Execute Service" dialog with vendor/location/job type/passKey params. |
| **ATOZClientView** | 2-column grid of ATOZ employees sorted: ONLINE → ACTIVE → alphabetical. Tap card to edit server, shift prefs, priority days/order. |
| **ClientFormView** | Edit client status, PIN, passKey, city category. Cascading State → City → JobType → Schedule picker sourced from `current_avail_job_schdules`. "Logout Client" sets status to `token_expired`. |
| **CandidateFormView** | Large form for candidate personal data: work auth, address + history, national ID, assessments. "Fetch from API" pulls live data. Validates YYYY-MM date format and 7-year address coverage. |

---

## 🔐 Permission Flags (Firestore `users` doc)

| Field | Effect |
|-------|--------|
| `status == "active"` | Login allowed |
| `has_form_access` | "Open Form" context menu item |
| `has_atoz_access` | ATOZ Clients button in portal |
| `has_service_logs_access` | Service logs panel in portal |
| `has_permission_to_clear_log` | "Clear Logs" button |

---

## 📋 Firestore Collections

| Collection | Purpose |
|-----------|---------|
| `users` | User profiles + permission flags |
| `client_sheet_2026` | Active clients |
| `client_sheet_2026_archived` | Archived clients |
| `atoz` | ATOZ employees |
| `service_logs` | Real-time service log stream |
| `form_data` | Candidate form data |
| `server_meta_data/active_job_data` | Available locations + job types |
| `current_avail_job_schdules` | Available job schedules |

---

## 📌 Requirements

- iOS 17+
- Xcode 15+
- Swift 5.9+