@echo off
echo ====================================================
echo  Launching Wehere Flutter App (Android / iOS / Web)
echo ====================================================
echo.
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Flutter SDK was not found in your system PATH.
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    echo or add your Flutter SDK bin folder to your PATH environment variable.
    echo.
    echo In the meantime, you can test all screens and interactions instantly
    echo via the interactive browser simulator by running 'run_preview.bat'.
    pause
    exit /b 1
)

echo [1/2] Fetching dependencies...
call flutter pub get

echo.
echo [2/2] Launching app...
call flutter run
pause
