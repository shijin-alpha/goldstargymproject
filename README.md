# GoldStar Gym Management System

A comprehensive Flutter-based gym management application with Firebase backend for managing gym members, memberships, and administrative tasks.

## 🎯 Features

### Admin Authentication
- PIN-based admin login system
- Secure Firebase authentication
- Session management

### Member Management
- ✅ Add new members
- ✅ View all members with real-time updates
- ✅ Edit member details
- ✅ Delete members
- ✅ Filter members by status (Active/Inactive)
- ✅ Automatic due date calculation (1 month after join date)
- ✅ Membership expiry tracking with color-coded alerts

### Automatic Due Date Calculation
The system automatically calculates membership due dates as exactly **1 month after the join date**, handling:
- Leap years (e.g., Jan 31, 2024 → Feb 29, 2024)
- February variations (e.g., Jan 31, 2026 → Feb 28, 2026)
- Months with 30 days (e.g., Mar 31 → Apr 30)
- Months with 31 days (e.g., Jan 10 → Feb 10)
- Year rollover (e.g., Dec 15, 2025 → Jan 15, 2026)

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Firestore
- **Authentication**: Firebase Auth
- **State Management**: StatefulWidget
- **Real-time Updates**: Firestore Streams

## 📦 Project Structure

```
lib/
├── main.dart                          # App entry point
├── firebase_options.dart              # Firebase configuration
├── models/
│   └── member.dart                    # Member data model
├── services/
│   ├── admin_auth_service.dart        # Admin authentication
│   └── member_service.dart            # Member CRUD operations
├── screens/
│   ├── admin_login_screen.dart        # Admin login UI
│   ├── admin_dashboard_screen.dart    # Dashboard UI
│   ├── members_list_screen.dart       # Members list UI
│   ├── add_member_screen.dart         # Add member form
│   └── edit_member_screen.dart        # Edit member form
└── utils/
    └── api_response.dart              # Standardized API responses
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.11.1 or higher)
- Dart SDK
- Firebase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd goldstar
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) and place in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) and place in `ios/Runner/`
   - Run Firebase configuration:
     ```bash
     flutterfire configure
     ```

4. **Set up environment variables**
   - Copy `.env.example` to `.env`
   - Add your configuration values

5. **Run the app**
   ```bash
   flutter run
   ```

## 📊 Database Structure

### Firestore Collections

#### `admins` Collection
```json
{
  "name": "Admin Name",
  "email": "admin@example.com",
  "phone": "+1234567890",
  "pin": "1234",
  "password": "hashed_password",
  "role": "admin",
  "status": "active",
  "lastLogin": "timestamp"
}
```

#### `members` Collection
```json
{
  "name": "John Doe",
  "phone": "+1234567890",
  "amount": 50.0,
  "joinDate": "2026-01-31T00:00:00.000Z",
  "dueDate": "2026-02-28T00:00:00.000Z",
  "status": "active",
  "createdAt": "2026-01-31T10:30:00.000Z"
}
```

## 🔐 Security

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Admins collection
    match /admins/{adminId} {
      allow read, write: if request.auth != null;
    }
    
    // Members collection
    match /members/{memberId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📱 Usage Guide

### Admin Login
1. Launch the app
2. Enter your admin PIN
3. Tap "Login"

### Managing Members

#### Add a New Member
1. From dashboard, tap "Manage Users"
2. Tap the "+" floating button
3. Fill in member details:
   - Full Name
   - Phone Number
   - Membership Amount
   - Join Date (due date calculated automatically)
   - Status (Active/Inactive)
4. Tap "Add Member"

#### View Members
- Members list shows all members with:
  - Name and phone
  - Membership amount
  - Due date with color coding:
    - 🔴 Red: Overdue
    - 🟠 Orange: Due within 7 days
    - ⚫ Gray: Normal
  - Status badge (Active/Inactive)

#### Edit a Member
1. Tap on any member card
2. Select "Edit Member"
3. Update the desired fields
4. Tap "Update Member"
   - If join date is changed, due date is automatically recalculated

#### Delete a Member
1. Tap on any member card
2. Select "Delete Member"
3. Confirm deletion

#### Filter Members
- Tap the filter icon (top right)
- Select: All Members, Active Only, or Inactive Only

## 🔧 API Reference

### Member Service Methods

#### Add Member
```dart
await memberService.addMember(
  name: 'John Doe',
  phone: '+1234567890',
  amount: 50.0,
  joinDate: DateTime(2026, 1, 31),
  status: 'active',
);
// dueDate automatically calculated as 2026-02-28
```

#### Get All Members
```dart
final response = await memberService.getAllMembers();
if (response.status == 'success') {
  final members = response.data; // List<Map<String, dynamic>>
}
```

#### Get Member by ID
```dart
final response = await memberService.getMemberById('memberId');
```

#### Update Member
```dart
await memberService.updateMember(
  memberId: 'abc123',
  name: 'Jane Doe',
  amount: 75.0,
  joinDate: DateTime(2024, 1, 31), // dueDate recalculated automatically
  status: 'inactive',
);
```

#### Delete Member
```dart
await memberService.deleteMember('memberId');
```

#### Real-time Stream
```dart
memberService.getMembersStream().listen((members) {
  // List<Member> with real-time updates
});
```

### Response Format

**Success Response:**
```json
{
  "status": "success",
  "message": "Operation completed successfully",
  "data": { ... }
}
```

**Error Response:**
```json
{
  "status": "error",
  "message": "Error description"
}
```

## 🧪 Testing

Run tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/member_service_test.dart
```

## 📝 Validation Rules

### Member Data Validation
- **Name**: Cannot be empty
- **Phone**: Cannot be empty
- **Amount**: Must be >= 0
- **Join Date**: Valid DateTime
- **Due Date**: Automatically calculated (1 month after join date)
- **Status**: Must be "active" or "inactive"

## 🎨 UI Features

### Color-Coded Status
- **Green**: Active members
- **Gray**: Inactive members

### Due Date Alerts
- **Red**: Membership expired
- **Orange**: Expiring within 7 days
- **Gray**: Not expiring soon

### Real-time Updates
- Changes appear instantly across all screens
- No manual refresh needed
- Multiple admins can work simultaneously

## 🔄 Due Date Calculation Examples

| Join Date | Due Date | Notes |
|-----------|----------|-------|
| 2026-01-10 | 2026-02-10 | Regular month |
| 2026-01-31 | 2026-02-28 | February (non-leap) |
| 2024-01-31 | 2024-02-29 | February (leap year) |
| 2026-03-31 | 2026-04-30 | 30-day month |
| 2025-12-15 | 2026-01-15 | Year rollover |

## 🐛 Troubleshooting

### Firebase Connection Issues
- Verify `google-services.json` is in the correct location
- Check Firebase project configuration
- Ensure Firestore is enabled in Firebase Console

### Login Issues
- Verify admin credentials in Firestore `admins` collection
- Check Firebase Authentication is enabled
- Ensure security rules allow authenticated access

### Build Issues
```bash
flutter clean
flutter pub get
flutter run
```

## 📄 License

This project is private and proprietary.

## 👥 Support

For issues or questions, contact the development team.

---

**Version:** 1.0.0  
**Last Updated:** 2026-03-05
