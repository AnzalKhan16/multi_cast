@echo off
echo ==============================================
echo Building MultiCast Windows Release Binary
echo ==============================================
cd /d "%~dp0\..\multicast_app"
call flutter clean
call flutter pub get
call flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Windows build failed!
    exit /b %ERRORLEVEL%
)
echo [SUCCESS] Windows binary built successfully at multicast_app\build\windows\x64\runner\Release\
