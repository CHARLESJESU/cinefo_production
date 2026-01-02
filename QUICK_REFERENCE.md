# Cinefo Production - Quick Reference Guide

## 🎯 File at a Glance

| File | Purpose | Key Functions/Features |
|------|---------|----------------------|
| **main.dart** | App entry point | Launches splash screen |
| **variables.dart** | Global state | API endpoints, session data (VSID, projectId, etc.) |
| **sessionexpired.dart** | Session expired screen | Shows when VSID expires |
| **importantfunc.dart** ⭐ | Utility functions | Session check, dialogs, API helpers |
| **loginscreen.dart** | Login & auth | Device verification, user login, SQLite storage |
| **RouteScreen.dart** | Main navigation | Bottom nav: Home, CallSheet, Reports |
| **MyHomescreen.dart** | Dashboard | User profile, production info, navigation |
| **callsheet.dart** | Callsheet list | View all callsheets (online + offline) |
| **offlinecreatecallsheet.dart** | Create callsheet | Offline-capable callsheet creation |
| **Reports.dart** | Reports list | All callsheet reports |
| **Reportdetails.dart** | Report details | Detailed callsheet report |
| **nfcUIDreader.dart** | NFC attendance | Scan NFC cards for attendance |
| **automaticexecution.dart** | Background sync | Syncs offline data to server |

## 🔑 Most Important Files

1. **variables.dart** - Global configuration and state
2. **importantfunc.dart** - All utility functions
3. **loginscreen.dart** - Authentication entry
4. **RouteScreen.dart** - Main navigation
5. **automaticexecution.dart** - Background sync

## 📊 Data Flow Cheat Sheet

### Login Flow
```
Device ID → Verify Device → Login Form → API Auth → Save SQLite → Navigate to Home
```

### API Call Pattern
```dart
// 1. Make API call with VSID
final response = await http.post(
  processSessionRequest,
  headers: {'VSID': vsid ?? ""},
  body: jsonEncode(data),
);

// 2. Check session expiration
if (checkSessionExpiration(context, response)) {
  return; // Session expired, user redirected
}

// 3. Process response
if (response.statusCode == 200) {
  // Your code
}
```

### Offline Data Pattern
```dart
// 1. Save to SQLite first
await db.insert('table_name', data);

// 2. Background sync handles server push
// (automaticexecution.dart)
```

## 🗄️ SQLite Tables

| Table | Purpose | Used By |
|-------|---------|---------|
| `login_data` | User login info | loginscreen.dart, MyHomescreen.dart |
| `callsheetoffline` | Offline callsheets | offlinecreatecallsheet.dart, callsheet.dart |
| `intime` | Offline attendance | nfcUIDreader.dart, intime.dart |

## 🔌 Key API Endpoints (from variables.dart)

```dart
processRequest          // Non-session API calls
processSessionRequest   // Session-authenticated calls (needs VSID)
```

## 📱 Common Imports

```dart
// Almost every screen needs:
import 'package:production/variables.dart';
import 'package:production/Screens/Home/importantfunc.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
```

## 🛠️ Quick Code Snippets

### Show Success Message
```dart
showsuccessPopUpSync(context, "Success!", () {
  // Optional callback
});
```

### Show Simple Message
```dart
showSimplePopUp(context, "Error message");
```

### Check Session
```dart
if (checkSessionExpiration(context, response)) {
  return; // Already handled
}
```

### Get VSID from SQLite
```dart
await printVSIDFromLoginData();
// Now vsid variable is populated
```

## 🎨 Navigation Cheat Sheet

```dart
// Navigate to screen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ScreenName(),
));

// Navigate and remove all previous
Navigator.pushAndRemoveUntil(context, 
  MaterialPageRoute(builder: (context) => ScreenName()),
  (route) => false,
);

// Go back
Navigator.pop(context);
```

## 📋 Session Variables (from variables.dart)

```dart
vsid              // Session ID (required for authenticated APIs)
projectId         // Current project
vmid              // Manager ID
vpid              // Production ID
productionTypeId  // Type of production
loginresponsebody // Full login response
```

## 🚨 Common Pitfalls

1. ❌ Forgetting to check session expiration after API call
2. ❌ Not calling `printVSIDFromLoginData()` before API calls
3. ❌ Hardcoding values instead of using `variables.dart`
4. ❌ Not handling offline scenarios
5. ❌ Duplicating utility functions instead of using `importantfunc.dart`

## ✅ Best Practices

1. ✅ Always check session after API calls with VSID
2. ✅ Save critical data to SQLite for offline support
3. ✅ Reuse functions from `importantfunc.dart`
4. ✅ Use global variables from `variables.dart`
5. ✅ Handle both online and offline states

## 🔍 Where to Find Things

| Need to... | Look in... |
|-----------|-----------|
| Add global variable | `variables.dart` |
| Add utility function | `importantfunc.dart` |
| Add dialog | `importantfunc.dart` |
| Modify login | `loginscreen.dart` |
| Add screen to nav | `RouteScreen.dart` |
| Check offline sync | `automaticexecution.dart` |
| Debug SQLite | `Tesing/Sqlitelist.dart` |

## 📞 Support

For questions about:
- **Session management** → Check `importantfunc.dart` and `sessionexpired.dart`
- **API calls** → Check `variables.dart` for endpoints
- **Offline sync** → Check `automaticexecution.dart`
- **Database** → Check SQLite tables in respective files
- **NFC** → Check `nfcUIDreader.dart`

---

*This quick reference complements the full PROJECT_DOCUMENTATION.md file*
