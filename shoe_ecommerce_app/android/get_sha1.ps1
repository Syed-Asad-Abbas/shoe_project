# PowerShell script to get SHA-1 fingerprints for debug and release keystores

# Find keytool in the Android SDK
$androidSdkPath = ""

# Try common Android SDK locations
$possibleLocations = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:USERPROFILE\AppData\Local\Android\Sdk",
    "C:\Android\Sdk",
    "D:\Android\Sdk",
    "$env:ANDROID_HOME",
    "$env:ANDROID_SDK_ROOT"
)

foreach ($location in $possibleLocations) {
    if (Test-Path $location) {
        $androidSdkPath = $location
        break
    }
}

if (-not $androidSdkPath) {
    Write-Host "Android SDK not found. Please set ANDROID_HOME environment variable." -ForegroundColor Red
    exit 1
}

# Find keytool in Android build-tools
$buildToolsDir = Join-Path $androidSdkPath "build-tools"
$keytoolPath = $null

if (Test-Path $buildToolsDir) {
    # Look for the latest version of build-tools
    $latestVersion = Get-ChildItem $buildToolsDir | Sort-Object Name -Descending | Select-Object -First 1
    if ($latestVersion) {
        $keytoolPath = Join-Path $latestVersion.FullName "keytool.exe"
        
        # If not there, try in platform-tools or tools
        if (-not (Test-Path $keytoolPath)) {
            $keytoolPath = Join-Path $androidSdkPath "platform-tools\keytool.exe"
            
            if (-not (Test-Path $keytoolPath)) {
                $keytoolPath = Join-Path $androidSdkPath "tools\keytool.exe"
            }
        }
    }
}

# If we couldn't find in Android SDK, try to check if Java is on the path
if (-not $keytoolPath -or -not (Test-Path $keytoolPath)) {
    # Try to find Java home
    $javaHome = $env:JAVA_HOME
    if ($javaHome -and (Test-Path $javaHome)) {
        $keytoolPath = Join-Path $javaHome "bin\keytool.exe"
    }
}

# Manual entry if all fails
if (-not $keytoolPath -or -not (Test-Path $keytoolPath)) {
    Write-Host "Keytool not found. Please enter the full path to keytool.exe:" -ForegroundColor Yellow
    $keytoolPath = Read-Host
    
    if (-not (Test-Path $keytoolPath)) {
        Write-Host "Invalid path. Exiting..." -ForegroundColor Red
        exit 1
    }
}

Write-Host "Using keytool at: $keytoolPath" -ForegroundColor Green

# For debug keystore
$debugKeystorePath = "$env:USERPROFILE\.android\debug.keystore"
$debugAlias = "androiddebugkey"
$debugPassword = "android"

if (Test-Path $debugKeystorePath) {
    Write-Host "Debug Keystore SHA-1:" -ForegroundColor Green
    & $keytoolPath -list -v -keystore $debugKeystorePath -alias $debugAlias -storepass $debugPassword | Select-String -Pattern "SHA1:"
} else {
    Write-Host "Debug keystore not found at $debugKeystorePath" -ForegroundColor Red
}

# For release keystore (if exists)
$releaseKeystorePath = ".\app\release-key.jks"
if (Test-Path $releaseKeystorePath) {
    $releaseAlias = Read-Host "Enter release keystore alias"
    $releasePassword = Read-Host "Enter release keystore password" -AsSecureString
    $releasePwdBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($releasePassword)
    $releasePwdString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($releasePwdBSTR)
    
    Write-Host "Release Keystore SHA-1:" -ForegroundColor Green
    & $keytoolPath -list -v -keystore $releaseKeystorePath -alias $releaseAlias -storepass $releasePwdString | Select-String -Pattern "SHA1:"
} else {
    Write-Host "No release keystore found at $releaseKeystorePath" -ForegroundColor Yellow
    Write-Host "It's recommended to create a release keystore for production builds." -ForegroundColor Yellow
}

Write-Host "`n======================" -ForegroundColor Cyan
Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "1. Copy the SHA-1 fingerprint above" -ForegroundColor Cyan
Write-Host "2. Go to Firebase console: https://console.firebase.google.com/" -ForegroundColor Cyan
Write-Host "3. Select your project" -ForegroundColor Cyan
Write-Host "4. Go to Project Settings > Your apps > Android app" -ForegroundColor Cyan
Write-Host "5. Click 'Add fingerprint' and paste the SHA-1 value" -ForegroundColor Cyan
Write-Host "6. Save changes and download the updated google-services.json" -ForegroundColor Cyan
Write-Host "7. Replace the existing google-services.json in your project" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 