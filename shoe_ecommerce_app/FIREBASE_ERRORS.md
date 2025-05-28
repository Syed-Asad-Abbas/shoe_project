# Firebase Authentication Troubleshooting Guide

## Common Firebase Authentication Errors

### ApiException: 10 (SHA-1 Certificate Fingerprint Mismatch)

**Error Message:**
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

**Cause:**
This error occurs when the SHA-1 certificate fingerprint used for building the app doesn't match what's registered in the Firebase console. This commonly happens in development when:
- You're using a different machine for development
- The debug keystore has been regenerated
- You're building with a release keystore not registered in Firebase

**Solution:**

1. **Run the SHA-1 fingerprint generator script:**
   ```
   cd android
   ./get_sha1.ps1
   ```

2. **Add the SHA-1 fingerprint to Firebase:**
   - Go to the [Firebase Console](https://console.firebase.google.com/)
   - Select your project
   - Navigate to Project Settings > Your apps > Android app
   - Click "Add fingerprint" and paste your SHA-1 value
   - Click "Save"

3. **Download and replace google-services.json:**
   - Download the updated google-services.json file
   - Replace the existing file in your project's `android/app/` directory

4. **Rebuild the app:**
   ```
   flutter clean
   flutter pub get
   flutter run
   ```

### Sign-in Canceled

**Error Message:**
```
PlatformException(sign_in_canceled, com.google.android.gms.common.api.ApiException: 12501: , null, null)
```

**Cause:**
This occurs when the user cancels the Google Sign-In process or when the sign-in was interrupted.

**Solution:**
This is a normal behavior when users decide not to proceed with Google Sign-In. No action is required.

### Network Error

**Error Message:**
```
PlatformException(network_error, com.google.android.gms.common.api.ApiException: 7: , null, null)
```

**Cause:**
There's no internet connection or the connection is poor.

**Solution:**
- Check your internet connection
- Retry when you have a stable connection

### Invalid Client ID

**Error Message:**
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

**Cause:**
The OAuth client ID in your google-services.json doesn't match what's provided to GoogleSignIn.

**Solution:**
- Make sure your google-services.json is the latest version
- Verify the web client ID in your Firebase console
- Make sure you're using the correct client ID in your GoogleSignIn initialization

### Missing Web Client ID

**Error Message:**
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

**Cause:**
Your Firebase project might be missing a Web Client ID, which is sometimes required for Google Sign-In.

**Solution:**
1. Go to Firebase Console > Authentication > Sign-in method
2. Enable Google as a sign-in provider
3. Go to Project Settings > Your apps
4. Add a web app if you don't have one (this will create a Web Client ID)
5. Download the updated google-services.json

## Other Firebase Authentication Tips

### Keep Dependencies Updated

Make sure your Firebase and Google Sign-In dependencies are up to date:

```yaml
firebase_core: latest_version
firebase_auth: latest_version
google_sign_in: latest_version
```

### Check Package Names

Ensure the package name in your Android app matches what's registered in Firebase:

- Check your `android/app/build.gradle.kts` or `android/app/build.gradle` for `applicationId`
- Verify it matches the package name in Firebase console

### Test on Physical Device

Google Sign-In may behave differently on emulators versus physical devices. When possible, test on a physical device.

### Clear App Data

If you've been testing the app and experiencing authentication issues, try:
- Uninstalling the app
- Clearing Google Play Services cache
- Reinstalling the app

### Enable Debug Logging

Add this code to see more detailed Firebase logs:

```dart
// In main.dart before runApp()
FirebaseAuth.instance.setLanguageCode("en");
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  print('authStateChanges: $user');
});
``` 