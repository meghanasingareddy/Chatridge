# PowerShell script to help download icon from icon.kitchen
# This script will guide you through downloading your icon

Write-Host "Icon Kitchen Icon Download Helper" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

$iconUrl = "https://icon.kitchen/i/H4sIAAAAAAAAAx2NsQ7DIBBD%2F8UzQ2e%2BokO2qsNFdxBUyEVAGkUR%2Fx7IYtlPln3hT3GXAnuBKf%2BmRZLAOopFDJyfzq1HhEReMMCbmMPqR7%2FqBvsyyMEv9XGz1qrpsVHcYK0ZJOU9josPaOWsgftS0NL1kBnfdgOKsk1KhQAAAA%3D%3D"

Write-Host "To download your icon from icon.kitchen:" -ForegroundColor Yellow
Write-Host "1. Open this URL in your browser:" -ForegroundColor Yellow
Write-Host "   $iconUrl" -ForegroundColor White
Write-Host ""
Write-Host "2. On the icon.kitchen page, click 'Export' or 'Download'" -ForegroundColor Yellow
Write-Host "3. Choose PNG format and download at 1024x1024 size" -ForegroundColor Yellow
Write-Host "4. Save the downloaded file as 'app_icon.png' in the 'assets/icon' folder" -ForegroundColor Yellow
Write-Host ""
Write-Host "Alternative: If icon.kitchen provides a direct download link, paste it below:" -ForegroundColor Yellow
$directLink = Read-Host "Direct download URL (or press Enter to skip)"

if ($directLink -and $directLink.Trim() -ne "") {
    Write-Host "Downloading icon from direct link..." -ForegroundColor Green
    try {
        Invoke-WebRequest -Uri $directLink -OutFile "assets/icon/app_icon.png"
        Write-Host "Icon downloaded successfully!" -ForegroundColor Green
        Write-Host "Now run: flutter pub get && flutter pub run flutter_launcher_icons" -ForegroundColor Cyan
    } catch {
        Write-Host "Error downloading icon: $_" -ForegroundColor Red
        Write-Host "Please download manually as described above." -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "Once you have downloaded and saved app_icon.png to assets/icon/," -ForegroundColor Cyan
    Write-Host "run these commands:" -ForegroundColor Cyan
    Write-Host "  flutter pub get" -ForegroundColor White
    Write-Host "  flutter pub run flutter_launcher_icons" -ForegroundColor White
}

