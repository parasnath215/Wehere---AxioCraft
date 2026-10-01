# Wehere - Automated Flutter SDK Setup Script for Windows
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "         Wehere - Flutter SDK Automated Installer           " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$installDir = "E:\flutter"

# Check if Flutter already exists in E:\flutter or C:\flutter
if (Test-Path "$installDir\bin\flutter.bat") {
    Write-Host "[✓] Found existing Flutter SDK at $installDir" -ForegroundColor Green
} elseif (Test-Path "C:\flutter\bin\flutter.bat") {
    $installDir = "C:\flutter"
    Write-Host "[✓] Found existing Flutter SDK at $installDir" -ForegroundColor Green
} else {
    Write-Host "[1/3] Cloning Flutter stable branch to $installDir (shallow clone for speed)..." -ForegroundColor Cyan
    Write-Host "Downloading Flutter SDK..." -ForegroundColor DarkGray
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git $installDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[X] Git clone failed. Please check your internet connection." -ForegroundColor Red
        exit 1
    }
}

# Add Flutter to User PATH if not already present
Write-Host "[2/3] Configuring Windows Environment PATH..." -ForegroundColor Cyan
$flutterBin = "$installDir\bin"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$flutterBin*") {
    $newPath = "$userPath;$flutterBin"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "[✓] Added $flutterBin to User PATH permanently." -ForegroundColor Green
} else {
    Write-Host "[✓] Flutter is already in your PATH." -ForegroundColor Green
}

# Update current session PATH
$env:PATH = "$env:PATH;$flutterBin"

# Verify Flutter
Write-Host "[3/3] Verifying Flutter installation..." -ForegroundColor Cyan
& "$flutterBin\flutter.bat" --version
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Flutter is ready! Run: flutter doctor                      " -ForegroundColor Green
Write-Host " Then run: flutter run -d android                           " -ForegroundColor Green
Write-Host " (Note: If using an existing terminal, reopen it to reload PATH) " -ForegroundColor DarkYellow
Write-Host "============================================================" -ForegroundColor Green
