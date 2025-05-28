# PowerShell script to get SHA-1 fingerprints for debug keystore
# This script will download OpenJDK if needed to run keytool

# Set TLS to 1.2 for downloading
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define paths
$tempDir = "$env:TEMP\sha1_helper"
$openJdkFile = "$tempDir\openjdk.zip"
$openJdkExtractDir = "$tempDir\openjdk"
$keystorePath = "$env:USERPROFILE\.android\debug.keystore"

# Create temp directory if it doesn't exist
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Function to download and extract OpenJDK
function Download-OpenJDK {
    Write-Host "Downloading OpenJDK to use keytool..." -ForegroundColor Yellow
    
    # Download OpenJDK
    $openJdkUrl = "https://aka.ms/download-jdk/microsoft-jdk-17.0.6-windows-x64.zip"
    
    try {
        Invoke-WebRequest -Uri $openJdkUrl -OutFile $openJdkFile
    }
    catch {
        Write-Host "Failed to download OpenJDK: $_" -ForegroundColor Red
        exit 1
    }
    
    # Extract OpenJDK
    Write-Host "Extracting OpenJDK..." -ForegroundColor Yellow
    
    if (-not (Test-Path $openJdkExtractDir)) {
        New-Item -ItemType Directory -Path $openJdkExtractDir | Out-Null
    }
    
    try {
        Expand-Archive -Path $openJdkFile -DestinationPath $openJdkExtractDir -Force
        
        # Find the bin directory containing keytool
        $keytoolPath = Get-ChildItem -Path $openJdkExtractDir -Recurse -Filter "keytool.exe" | Select-Object -First 1 -ExpandProperty FullName
        
        if (-not $keytoolPath) {
            throw "keytool.exe not found in extracted OpenJDK"
        }
        
        return $keytoolPath
    }
    catch {
        Write-Host "Failed to extract OpenJDK: $_" -ForegroundColor Red
        exit 1
    }
}

# Try to find keytool in common locations
$keytoolPath = $null

# Check if JAVA_HOME is set
if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\keytool.exe")) {
    $keytoolPath = "$env:JAVA_HOME\bin\keytool.exe"
}
# Check if keytool is in the PATH
elseif (Get-Command "keytool.exe" -ErrorAction SilentlyContinue) {
    $keytoolPath = "keytool.exe" 
}
# Check Android SDK locations
elseif ($env:ANDROID_HOME -and (Test-Path "$env:ANDROID_HOME\tools\bin\keytool.exe")) {
    $keytoolPath = "$env:ANDROID_HOME\tools\bin\keytool.exe"
}
elseif ($env:ANDROID_SDK_ROOT -and (Test-Path "$env:ANDROID_SDK_ROOT\tools\bin\keytool.exe")) {
    $keytoolPath = "$env:ANDROID_SDK_ROOT\tools\bin\keytool.exe"
}
# Try to find in common Java locations
elseif (Test-Path "C:\Program Files\Java") {
    $javaVersions = Get-ChildItem "C:\Program Files\Java" -Directory | Sort-Object Name -Descending
    foreach ($version in $javaVersions) {
        if (Test-Path "$($version.FullName)\bin\keytool.exe") {
            $keytoolPath = "$($version.FullName)\bin\keytool.exe"
            break
        }
    }
}

# If keytool is not found, download OpenJDK
if (-not $keytoolPath -or -not (Test-Path $keytoolPath)) {
    $keytoolPath = Download-OpenJDK
}

Write-Host "Using keytool at: $keytoolPath" -ForegroundColor Green

# Create debug keystore if it doesn't exist
if (-not (Test-Path $keystorePath)) {
    Write-Host "Debug keystore not found. Creating one..." -ForegroundColor Yellow
    
    $keystoreDir = Split-Path $keystorePath -Parent
    if (-not (Test-Path $keystoreDir)) {
        New-Item -ItemType Directory -Path $keystoreDir | Out-Null
    }
    
    & $keytoolPath -genkey -v -keystore $keystorePath -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US"
    
    if (-not (Test-Path $keystorePath)) {
        Write-Host "Failed to create debug keystore." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Debug keystore created successfully." -ForegroundColor Green
}

# Get SHA-1 fingerprint
Write-Host "`nGetting SHA-1 fingerprint..." -ForegroundColor Green
$output = & $keytoolPath -list -v -keystore $keystorePath -alias androiddebugkey -storepass android

# Extract SHA-1 fingerprint
$sha1Line = $output | Select-String -Pattern "SHA1:"
if ($sha1Line) {
    $sha1 = $sha1Line -replace ".*SHA1: (.*)", '$1'
    Write-Host "`nYour SHA-1 fingerprint is:" -ForegroundColor Green
    Write-Host $sha1 -ForegroundColor Cyan
    
    # Save to a file for easy copying
    $sha1 | Out-File -FilePath "$tempDir\sha1_fingerprint.txt" -Force
    Write-Host "SHA-1 fingerprint saved to: $tempDir\sha1_fingerprint.txt" -ForegroundColor Green
} else {
    Write-Host "Could not extract SHA-1 fingerprint from keytool output." -ForegroundColor Red
}

Write-Host "`n======================" -ForegroundColor Cyan
Write-Host "INSTRUCTIONS:" -ForegroundColor Cyan
Write-Host "1. Copy the SHA-1 fingerprint above" -ForegroundColor Cyan
Write-Host "2. Go to Firebase console: https://console.firebase.google.com/" -ForegroundColor Cyan
Write-Host "3. Select your project" -ForegroundColor Cyan
Write-Host "4. Go to Project Settings > Your apps > Android app" -ForegroundColor Cyan
Write-Host "5. Click 'Add fingerprint' and paste the SHA-1 value" -ForegroundColor Cyan
Write-Host "6. Save changes and download the updated google-services.json" -ForegroundColor Cyan
Write-Host "7. Replace the existing google-services.json in your project's android/app directory" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") 