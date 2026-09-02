Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "Building MultiCast Windows Release Binary" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Set-Location -Path "$PSScriptRoot\..\multicast_app"
flutter clean
flutter pub get
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Windows build failed!"
    exit $LASTEXITCODE
}
Write-Host "[SUCCESS] Windows binary built successfully at multicast_app\build\windows\x64\runner\Release\" -ForegroundColor Green
