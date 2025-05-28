@echo off
setlocal enabledelayedexpansion

echo Attempting to find SHA-1 fingerprint for your debug keystore...
echo.

:: Try to use keytool from Android Studio
set "KEYSTORE_PATH=%USERPROFILE%\.android\debug.keystore"
set "KEYSTORE_PASS=android"
set "KEY_ALIAS=androiddebugkey"

:: List of possible locations for keytool
set "POSSIBLE_JAVA_PATHS=C:\Program Files\Java C:\Program Files (x86)\Java C:\Program Files\Android\Android Studio\jre C:\Program Files\Android\Android Studio\jbr"

:: Try Android SDK paths
if defined ANDROID_HOME (
    echo Checking ANDROID_HOME: %ANDROID_HOME%
    set "BUILD_TOOLS_DIR=%ANDROID_HOME%\build-tools"
    for /f "delims=" %%i in ('dir /b /ad /o-n "%BUILD_TOOLS_DIR%"') do (
        set "KEYTOOL_PATH=%BUILD_TOOLS_DIR%\%%i\keytool.exe"
        if exist "!KEYTOOL_PATH!" (
            goto :found_keytool
        )
    )
)

:: Try common Java installations
for %%j in (%POSSIBLE_JAVA_PATHS%) do (
    if exist "%%j" (
        for /f "delims=" %%i in ('dir /b /s /a-d "%%j\bin\keytool.exe" 2^>nul') do (
            set "KEYTOOL_PATH=%%i"
            goto :found_keytool
        )
    )
)

:: Try finding using where command
for /f "delims=" %%i in ('where keytool 2^>nul') do (
    set "KEYTOOL_PATH=%%i"
    goto :found_keytool
)

echo.
echo Could not find keytool automatically.
echo.
echo Please enter the full path to keytool.exe:
set /p KEYTOOL_PATH=

if not exist "%KEYTOOL_PATH%" (
    echo Invalid path provided.
    exit /b 1
)

:found_keytool
echo Found keytool at: %KEYTOOL_PATH%
echo.

if not exist "%KEYSTORE_PATH%" (
    echo Debug keystore not found at %KEYSTORE_PATH%
    echo.
    echo Will try to recreate debug keystore...
    echo.
    
    "%KEYTOOL_PATH%" -genkey -v -keystore "%KEYSTORE_PATH%" -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if not exist "%KEYSTORE_PATH%" (
        echo Failed to create debug keystore.
        exit /b 1
    )
    
    echo Debug keystore created successfully.
)

echo.
echo Debug Keystore SHA-1:
"%KEYTOOL_PATH%" -list -v -keystore "%KEYSTORE_PATH%" -alias "%KEY_ALIAS%" -storepass "%KEYSTORE_PASS%" | findstr /C:"SHA1:"

echo.
echo ======================
echo INSTRUCTIONS:
echo 1. Copy the SHA-1 fingerprint above
echo 2. Go to Firebase console: https://console.firebase.google.com/
echo 3. Select your project
echo 4. Go to Project Settings ^> Your apps ^> Android app
echo 5. Click "Add fingerprint" and paste the SHA-1 value
echo 6. Save changes and download the updated google-services.json
echo 7. Replace the existing google-services.json in your project
echo ======================
echo.

pause 