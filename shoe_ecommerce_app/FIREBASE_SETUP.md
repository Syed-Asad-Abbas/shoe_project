# Firebase Google Sign-In Setup Guide

This document outlines how to properly set up Firebase Google Sign-In authentication in the Shoe E-commerce app.

## Setup Requirements

1. **Firebase Project**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Register your Android app with package name `com.shoeecom.shoe_ecommerce_app`
   - Download the `google-services.json` file and place it in the `android/app/` directory

2. **Google Cloud Console Setup**
   - Enable Google Sign-In API in the Google Cloud Console
   - Configure OAuth consent screen
   - Create OAuth 2.0 client ID

## Dependencies Added
The following dependencies have been added to the project:
```yaml
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
google_sign_in: ^6.1.6
```

## Implementation Details

### Backend Changes
- Added new endpoints for Firebase authentication:
  - `/api/v1/auth/login/firebase` - For logging in Firebase users
  - `/api/v1/auth/register/firebase` - For registering new Firebase users

### Client Changes
1. **Firebase Service**
   - Created a new service to handle Firebase authentication in `lib/services/firebase_service.dart`
   - Implemented methods for Google Sign-In, Sign-Out, and communicating with the backend

2. **Auth Provider**
   - Updated to support both traditional and Firebase authentication
   - Added methods to handle Google Sign-In flow

3. **User Model**
   - Added support for Firebase-specific fields:
     - `firebaseUid` - Firebase User ID
     - `photoUrl` - Profile photo URL from Google account

4. **Login Screen**
   - Added Google Sign-In button
   - Implemented sign-in flow

## How Google Sign-In Affects User Authentication

When a user signs in with Google:

1. Firebase authenticates the user through Google
2. The app receives the Firebase user credentials
3. The app sends these credentials to our backend
4. The backend:
   - Checks if the user already exists (by email)
   - If yes, links the Firebase UID to the existing user
   - If no, creates a new user with the Firebase information
5. The backend returns a JWT token and user information
6. The app saves this token and user information locally

This approach allows for:
- Seamless authentication using Google accounts
- Consistent user experience across authentication methods
- Proper integration with the existing backend user system

## Testing
To test Google Sign-In, you need:
1. A real device or emulator with Google Play Services
2. A properly configured Firebase project
3. An internet connection

## Troubleshooting
- Ensure your `google-services.json` is correct and up-to-date
- If sign-in fails, check the Firebase console for authentication errors
- Verify that your backend API endpoints are correctly implemented
- Check your network connection if the backend communication fails 