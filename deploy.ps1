# SafeLink SOS System - Quick Deployment Script
# Run this script to deploy Firebase Functions

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  SafeLink SOS Alert System Deployment" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Navigate to functions directory
Write-Host "Step 1: Navigating to functions directory..." -ForegroundColor Yellow
Set-Location -Path "c:\Users\Admin Sania\Downloads\Telegram Desktop\safelink_n signup auth\safelink_n\functions"
Write-Host "✅ Done" -ForegroundColor Green
Write-Host ""

# Step 2: Install dependencies
Write-Host "Step 2: Installing dependencies..." -ForegroundColor Yellow
npm install
Write-Host "✅ Done" -ForegroundColor Green
Write-Host ""

# Step 3: Deploy functions
Write-Host "Step 3: Deploying Firebase Functions..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Gray
firebase deploy --only functions

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Copy the function URLs from above" -ForegroundColor White
Write-Host "2. Update lib/data/services/alert_service.dart with your function URL" -ForegroundColor White
Write-Host "3. Update web/proctorial_dashboard.html with your Firebase config" -ForegroundColor White
Write-Host "4. See DEPLOYMENT_GUIDE.md for detailed instructions" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
