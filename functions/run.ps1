# PowerShell script to create staff accounts
# Run: .\run.ps1

# Set environment variable for service account key
$env:GOOGLE_APPLICATION_CREDENTIALS = "serviceAccountKey.json"

# Run the Node.js script
node scripts/create_staff_accounts.js

Write-Host "`n✅ Staff accounts created successfully!" -ForegroundColor Green
Write-Host "Login with:" -ForegroundColor Yellow
Write-Host "  Proctorial: proctor@nstu.edu.bd / Proctor1" -ForegroundColor Cyan
Write-Host "  Security: security@nstu.edu.bd / Security1" -ForegroundColor Cyan
