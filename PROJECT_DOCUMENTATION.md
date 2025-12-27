# Cinefo Production App - Complete Project Documentation

## 📱 Project Overview

**Project Name:** Cinefo Production Management System  
**Platform:** Flutter (Cross-platform - Android/iOS)  
**Purpose:** A production management application for film/TV production houses to manage callsheets, attendance, crew members, and production logistics.

### Key Features:
1. **Login & Authentication** - Secure login with device ID verification
2. **Call Sheet Management** - Create, view, and manage production call sheets
3. **Attendance Tracking** - NFC-based attendance for crew members
4. **Reports** - View production reports and call sheet history
5. **Configuration** - Manage crew members, units, and production details
6. **Offline Support** - Offline data storage with SQLite
7. **Session Management** - Automatic session expiration handling

---

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── variables.dart                     # Global variables and API endpoints
├── sessionexpired.dart                # Session expired screen
├── updatechecker.dart                 # OTA update checker
├── methods.dart                       # [DEPRECATED] Moved to importantfunc.dart
│
├── Profile/                           # User Profile Module
│   ├── profilesccreen.dart           # View user profile
│   └── changepassword.dart           # Change password functionality
│
├── Screens/                          # Main App Screens
│   ├── splash/                       # App Launch
│   │   └── splashscreen.dart
│   │
│   ├── Login/                        # Authentication
│   │   └── loginscreen.dart          # Login screen with device verification
│   │
│   ├── Route/                        # Navigation
│   │   └── RouteScreen.dart          # Bottom navigation bar (Home, CallSheet, Reports)
│   │
│   ├── Home/                         # Home Module
│   │   ├── MyHomescreen.dart         # Main dashboard
│   │   ├── importantfunc.dart        # ⭐ Utility functions (Session, API, Dialogs)
│   │   ├── approvalstatus.dart       # Approval notifications
│   │   ├── automaticexecution.dart   # Background sync processes
│   │   ├── colorcode.dart            # Color codes for UI
│   │   └── offline_callsheet_detail_screen.dart  # Offline callsheet details
│   │
│   ├── callsheet/                    # Call Sheet Module
│   │   ├── callsheet.dart            # View callsheets
│   │   └── offlinecreatecallsheet.dart  # Create callsheet (offline capable)
│   │
│   ├── Attendance/                   # Attendance Module
│   │   ├── nfcUIDreader.dart        # NFC attendance scanner
│   │   ├── dailogei.dart            # Attendance dialogs
│   │   ├── intime.dart              # In-time attendance
│   │   ├── outtimecharles.dart      # Out-time attendance
│   │   ├── encryption.dart          # Data encryption utilities
│   │   └── nfcnotifier.dart         # NFC state notifier
│   │
│   ├── report/                       # Reports Module
│   │   ├── Reports.dart              # Callsheet reports list
│   │   └── Reportdetails.dart        # Individual report details
│   │
│   ├── configuration/                # Configuration Module
│   │   ├── configuration.dart        # Main configuration screen
│   │   ├── individualunitpage.dart   # Individual unit config
│   │   ├── unitmemberperson.dart     # Unit member management
│   │   ├── production.dart           # Production crew config
│   │   ├── technician.dart           # Technician config
│   │   ├── lightman.dart             # Lighting crew config
│   │   └── journiarartist.dart       # Junior artist config
│   │
│   └── apicalls/                     # API Module
│       └── apicall.dart              # Generic API call handlers
│
└── Tesing/                           # Testing/Debug
    └── Sqlitelist.dart               # SQLite database viewer

```

---

## 🔑 Core Files Explained

### 1. **main.dart**
- **Purpose:** Application entry point
- **Key Responsibilities:**
  - Initialize the Flutter app
  - Set up initial route (Splash screen)
  - Configure material app theme
- **Connects to:** `splashscreen.dart`

### 2. **variables.dart**
- **Purpose:** Global state management and API configuration
- **Key Contents:**
  - API endpoints (processRequest, processSessionRequest)
  - Global variables (vsid, projectId, vmid, etc.)
  - User session data (loginresponsebody, loginresult)
  - Device and project information
- **Used by:** Almost every file that makes API calls
- **Why:** Centralized configuration makes it easy to update API URLs and share session data

### 3. **sessionexpired.dart**
- **Purpose:** Screen shown when user session expires
- **Functionality:**
  - Displays session expired message
  - Redirects to login screen
  - Clears session data
- **Triggered by:** `checkSessionExpiration()` function in importantfunc.dart
- **Connects to:** `loginscreen.dart`

### 4. **updatechecker.dart**
- **Purpose:** Check for app updates (OTA - Over The Air)
- **Functionality:**
  - Check server for new app versions
  - Download and install updates
  - Handle update dialogs
- **Used by:** `loginscreen.dart` (on login)

---

## 🏠 Home Module Files

### **MyHomescreen.dart**
- **Purpose:** Main dashboard after login
- **Features:**
  - Display user profile information
  - Show production details
  - Navigation drawer with Device ID, NFC, vSync
  - Logout functionality
- **Data Sources:**
  - SQLite database (login_data table)
- **Connects to:**
  - `profilesccreen.dart` (View Profile)
  - `changepassword.dart` (Change Password)
  - `nfcUIDreader.dart` (NFC Scanner)
  - `Sqlitelist.dart` (vSync - SQLite viewer)
  - `loginscreen.dart` (Logout)

### **importantfunc.dart** ⭐ CRITICAL FILE
- **Purpose:** Central utility functions used across the app
- **Key Functions:**

#### Session Management:
```dart
bool checkSessionExpiration(context, response)
```
- Checks API response for session expiration
- Auto-navigates to session expired screen
- Used after every API call with VSID header

#### API Helpers:
```dart
Future<Map> decryptapi({encryptdata, vsid})
Future<Map> datacollectionapi({vcid, rfid, vsid})
Future<void> printVSIDFromLoginData()
```
- Decrypt encrypted API responses
- Data collection API calls
- Fetch VSID from SQLite database

#### Dialog Utilities:
```dart
void showmessage(context, message, ok)
void showsuccessPopUp(context, message, onDismissed)
void showsuccessPopUpSync(context, message, onDismissed)
void showSimplePopUp(context, message)
Widget commonRow(imagePath, text, number)
```
- Display various types of dialogs
- Success/error message popups
- Common UI widgets

- **Used by:** Almost all screens that need API calls or dialogs
- **Why it's important:** Centralized utility functions prevent code duplication

### **automaticexecution.dart**
- **Purpose:** Background synchronization processes
- **Key Functions:**
  - `processAllOfflineCallSheets()` - Sync offline callsheets to server
  - `processAllIntimeRecords()` - Sync attendance records
  - `processAllCloseCallSheets()` - Process closed callsheets
- **Runs:** Periodically in the background
- **Uses:** SQLite for offline data, API calls for syncing
- **Why:** Ensures offline data is eventually synced when online

### **approvalstatus.dart**
- **Purpose:** Show approval/notification status
- **Features:**
  - Display pending approvals
  - Notification center
- **Accessed from:** MyHomescreen navigation

---

## 🔐 Login Module

### **loginscreen.dart**
- **Purpose:** User authentication and device verification
- **Key Features:**
  1. **Device ID Verification:** Uses IMEI for device identification
  2. **User Login:** Mobile number + password authentication
  3. **OTA Update Check:** Checks for app updates on login
  4. **Data Storage:** Saves login data to SQLite
  5. **Session Management:** Manages user session (VSID)

- **Flow:**
  ```
  App Launch → Get Device ID → Verify Device with Server → 
  Show Login Form → Authenticate → Save to SQLite → Navigate to RouteScreen
  ```

- **SQLite Tables:**
  - `login_data` - Stores user login information

- **API Calls:**
  - Device ID verification
  - Base URL fetch
  - User login authentication
  - Update check

- **Connects to:**
  - `RouteScreen.dart` (on successful login)
  - `updatechecker.dart` (for updates)
  - `importantfunc.dart` (for utilities)

---

## 🧭 Navigation

### **RouteScreen.dart**
- **Purpose:** Main navigation container with bottom navigation bar
- **Navigation Items:**
  1. **Home** → MyHomescreen.dart
  2. **CallSheet** → CallSheet.dart
  3. **Reports** → Reports.dart

- **State Management:**
  - Maintains selected index
  - Passes project and callsheet IDs to child screens
  - Handles production type specific navigation

- **Used by:** As the main container after login
- **Connects to:** Home, CallSheet, and Reports screens

---

## 📋 Call Sheet Module

### **callsheet.dart**
- **Purpose:** View and manage call sheets
- **Features:**
  - List of all callsheets (online + offline)
  - Filter and search callsheets
  - View callsheet details
- **Data Sources:**
  - API for online callsheets
  - SQLite (`callsheetoffline` table) for offline
- **Connects to:**
  - `offline_callsheet_detail_screen.dart` (view details)
  - `offlinecreatecallsheet.dart` (create new)

### **offlinecreatecallsheet.dart**
- **Purpose:** Create new call sheets with offline capability
- **Features:**
  - Form for callsheet details (name, shift, location, etc.)
  - GPS location capture
  - Offline storage
  - Auto-sync when online
- **SQLite Tables:**
  - `callsheetoffline` - Stores offline callsheets
- **Sync:** Handled by `automaticexecution.dart`

---

## 📊 Reports Module

### **Reports.dart**
- **Purpose:** Display all callsheet reports
- **Features:**
  - List of callsheets with status
  - Online and offline callsheets
  - Navigation to detailed reports
- **API Call:** Fetches callsheet list with VSID authentication
- **Session Check:** Uses `checkSessionExpiration()` after API call
- **Connects to:** `Reportdetails.dart`

### **Reportdetails.dart**
- **Purpose:** Detailed view of a specific callsheet report
- **Features:**
  - Attendance details
  - Callsheet information
  - Export/share functionality
- **API Call:** Fetches detailed report data
- **Session Check:** Uses `checkSessionExpiration()`

---

## 👥 Attendance Module

### **nfcUIDreader.dart**
- **Purpose:** NFC-based attendance scanning
- **Features:**
  - Scan NFC cards/tags
  - Decrypt NFC data
  - Record attendance (in-time/out-time)
  - Offline capable
- **Flow:**
  ```
  Scan NFC → Decrypt → Get Person Info → Record Attendance → Save to SQLite → Sync
  ```
- **Uses:**
  - `encryption.dart` for decryption
  - `datacollectionapi()` from importantfunc.dart
  - SQLite (`intime` table) for offline storage
- **Sync:** Handled by `automaticexecution.dart`

### **dailogei.dart**
- **Purpose:** Attendance dialog interfaces
- **Features:**
  - Show attendance confirmation
  - Display crew member details
  - Handle attendance errors

### **intime.dart & outtimecharles.dart**
- **Purpose:** Manual attendance entry (in-time and out-time)
- **Features:**
  - Manual time entry
  - Crew member selection
  - Offline storage

### **encryption.dart**
- **Purpose:** Encrypt/decrypt NFC data
- **Why:** Secure NFC card data transmission

---

## ⚙️ Configuration Module

### **configuration.dart**
- **Purpose:** Main configuration screen
- **Features:**
  - List all crew units
  - Navigate to specific configurations
- **Connects to:**
  - `individualunitpage.dart`
  - `unitmemberperson.dart`
  - Various crew type configurations

### **unitmemberperson.dart**
- **Purpose:** Manage unit members
- **Features:**
  - Add/edit/delete crew members
  - Assign to units
  - Update member details
- **API Calls:** CRUD operations for members

### Crew Type Configurations:
- **production.dart** - Production crew
- **technician.dart** - Technical crew
- **lightman.dart** - Lighting crew
- **journiarartist.dart** - Junior artists

All follow similar patterns for crew management.

---

## 💾 Data Flow & Architecture

### **SQLite Database (Local Storage)**

**Tables:**
1. **login_data** - User login information
2. **callsheetoffline** - Offline callsheets
3. **intime** - Offline attendance records

**Why SQLite:**
- Offline capability
- Fast local access
- Sync with server when online

### **API Communication**

**Headers:**
- `VMETID` - API encryption key (different for each endpoint)
- `VSID` - Session ID (obtained after login)
- `Content-Type` - application/json

**Endpoints (from variables.dart):**
- `processRequest` - Non-session API calls
- `processSessionRequest` - Session-authenticated API calls

**Flow:**
```
App → API Call with VSID → Check Session Expiration → 
Process Response OR Navigate to SessionExpired
```

### **Session Management Flow**

1. **Login:**
   ```
   loginscreen.dart → API Login → Get VSID → Save to variables.dart & SQLite
   ```

2. **API Calls:**
   ```
   Any Screen → API Call with VSID → checkSessionExpiration() → 
   Continue OR Navigate to sessionexpired.dart
   ```

3. **Session Expired:**
   ```
   sessionexpired.dart → Clear Session Data → Navigate to loginscreen.dart
   ```

---

## 🔗 File Dependencies Map

### High-Level Dependencies:

```
main.dart
  └── splashscreen.dart
       └── loginscreen.dart
            ├── importantfunc.dart
            ├── variables.dart
            └── RouteScreen.dart
                 ├── MyHomescreen.dart
                 │    ├── importantfunc.dart
                 │    └── SQLite (login_data)
                 │
                 ├── callsheet.dart
                 │    ├── importantfunc.dart (session check)
                 │    ├── SQLite (callsheetoffline)
                 │    └── offline_callsheet_detail_screen.dart
                 │
                 └── Reports.dart
                      ├── importantfunc.dart (session check)
                      └── Reportdetails.dart
```

### Common Dependencies:

**Almost all screens import:**
- `variables.dart` - For global state and API endpoints
- `importantfunc.dart` - For utility functions
- `package:http` - For API calls
- `package:sqflite` - For local database

---

## 🎯 Key Concepts for New Developers

### 1. **VSID (Session ID)**
- Obtained after successful login
- Required for all authenticated API calls
- Stored in `variables.dart` and SQLite
- Validated on every API call

### 2. **Offline-First Architecture**
- All critical data saved to SQLite first
- Background sync processes handle server communication
- User can work offline, data syncs later

### 3. **Session Expiration Handling**
- Every API call with VSID must check for session expiration
- Use `checkSessionExpiration(context, response)` after API calls
- Automatic navigation to session expired screen

### 4. **Device ID Verification**
- Device IMEI used for device authentication
- Each device must be verified before login
- Prevents unauthorized devices

### 5. **Project ID & Production Types**
- Different production types have different workflows
- `productionTypeId` determines UI flow and features
- `projectId` filters data for specific productions

---

## 🚀 Getting Started (For New Developers)

### Step 1: Understanding the Entry Points
1. Start with `main.dart` → `splashscreen.dart` → `loginscreen.dart`
2. Understand the login flow and session management

### Step 2: Core Utilities
1. Read `variables.dart` - Know what global variables exist
2. Study `importantfunc.dart` - All reusable functions
3. Understand session checking mechanism

### Step 3: Main Features
1. **Navigation:** `RouteScreen.dart`
2. **Home:** `MyHomescreen.dart`
3. **Call Sheets:** `callsheet.dart` → offline capability
4. **Attendance:** `nfcUIDreader.dart` → NFC scanning
5. **Reports:** `Reports.dart` → data viewing

### Step 4: Database
1. Check SQLite schema in `loginscreen.dart`, `offlinecreatecallsheet.dart`
2. Understand offline sync in `automaticexecution.dart`

### Step 5: API Integration
1. All API endpoints in `variables.dart`
2. Session-based calls use `processSessionRequest`
3. Always check session expiration after API calls

---

## 🛠️ Common Development Tasks

### Adding a New Screen
1. Create screen file in appropriate `Screens/` folder
2. Import `variables.dart` and `importantfunc.dart`
3. Add navigation route in calling screen
4. If using API: Add session expiration check

### Adding a New API Call
1. Get endpoint and VMETID key
2. Use `http.post()` with VSID header
3. Call `checkSessionExpiration(context, response)`
4. Process response data

### Adding Offline Capability
1. Create SQLite table in appropriate file
2. Save data locally first
3. Add sync logic to `automaticexecution.dart`
4. Handle online/offline states

### Adding a New Dialog
1. Add function to `importantfunc.dart`
2. Follow existing patterns (showmessage, showSimplePopUp)
3. Import and use in your screen

---

## 📚 Important Notes

1. **Don't modify `variables.dart` lightly** - It's used everywhere
2. **Always use `importantfunc.dart`** - Don't duplicate utility code
3. **Session checks are critical** - Don't skip them
4. **Test offline** - Ensure SQLite sync works
5. **Keep `methods.dart` deprecated** - All moved to importantfunc.dart

---

## 🐛 Troubleshooting Common Issues

### Issue: "Session Expired" appears randomly
- **Cause:** VSID not being sent or expired
- **Fix:** Check if `printVSIDFromLoginData()` is called before API calls

### Issue: Offline data not syncing
- **Cause:** `automaticexecution.dart` not running or errors
- **Fix:** Check console logs for sync process errors

### Issue: NFC not working
- **Cause:** Permissions or NFC not supported
- **Fix:** Check `isNfcSupported()` and request permissions

### Issue: Login fails even with correct credentials
- **Cause:** Device ID not verified
- **Fix:** Check device verification API call and IMEI access

---

## 📞 Module Communication Flow

```
User Action → Screen → Check Session → API Call → Process Response → 
Update UI → Save to SQLite (if offline) → Background Sync
```

---

This documentation should give any new developer a complete understanding of the Cinefo Production app structure, file purposes, and how everything connects together!
