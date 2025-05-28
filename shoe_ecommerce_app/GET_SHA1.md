# How to Get SHA-1 Fingerprint for Firebase

This guide provides multiple methods to obtain your SHA-1 fingerprint for Firebase configuration.

## Method 1: Using Gradle (Recommended)

This is the most reliable method as it uses the same build tools as your Flutter app:

1. Open a terminal/command prompt
2. Navigate to your project's android directory:
   ```
   cd android
   ```
3. Run the Gradle task:
   ```
   ./gradlew signingReport
   ```
   On Windows, use:
   ```
   gradlew signingReport
   ```
4. Look for the SHA-1 fingerprint in the output

## Method 2: Using the Batch Script (Windows)

1. Navigate to your project's android directory:
   ```
   cd android
   ```
2. Run the batch file:
   ```
   alternate_sha1.bat
   ```
3. The script will find keytool automatically and display your SHA-1 fingerprint

## Method 3: Using the PowerShell Script (Windows)

1. Navigate to your project's android directory:
   ```
   cd android
   ```
2. Run the PowerShell script:
   ```
   .\get_sha1.ps1
   ```
3. If prompted for the location of keytool, provide the full path to keytool.exe

## Method 4: Manual Method

If all else fails, use these manual steps:

1. Find your debug keystore location (usually at `C:\Users\{username}\.android\debug.keystore`)
2. Find keytool in your JDK installation (usually at `C:\Program Files\Java\jdk{version}\bin\keytool.exe`)
3. Run this command:
   ```
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
4. Look for the SHA-1 value in the output

## After Getting the SHA-1 Fingerprint

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Project Settings > Your apps > Android app
4. Click "Add fingerprint" and paste your SHA-1 value
5. Click "Save"
6. Download the updated google-services.json
7. Replace the existing file in your project's `android/app/` directory

## Troubleshooting

If you encounter issues:

1. Make sure you have JDK installed and set up properly
2. Check if ANDROID_HOME environment variable is set correctly
3. Try running Flutter with the --verbose flag to see more detailed error messages:
   ```
   flutter run --verbose
   ```

For more information, see the [Firebase Authentication Troubleshooting Guide](./FIREBASE_ERRORS.md). 