# PowerShell Script to Prepare and Upload Rate Card Project to AWS EC2
# Run this script from your project directory

param(
    [Parameter(Mandatory=$true)]
    [string]$KeyPath,
    
    [Parameter(Mandatory=$true)]
    [string]$EC2IP,
    
    [string]$ProjectName = "ratecard-app"
)

Write-Host "🚀 Preparing Rate Card Project for AWS EC2 Deployment" -ForegroundColor Green

# Validate inputs
if (-not (Test-Path $KeyPath)) {
    Write-Error "SSH key file not found at: $KeyPath"
    exit 1
}

# Set variables
$ArchiveName = "$ProjectName.tar.gz"
$ProjectDir = Get-Location

Write-Host "📁 Project Directory: $ProjectDir" -ForegroundColor Yellow
Write-Host "🔑 SSH Key: $KeyPath" -ForegroundColor Yellow
Write-Host "🌐 EC2 IP: $EC2IP" -ForegroundColor Yellow

# Create archive excluding unnecessary files
Write-Host "📦 Creating project archive..." -ForegroundColor Cyan

$excludePatterns = @(
    '--exclude=node_modules',
    '--exclude=.git',
    '--exclude=dist',
    '--exclude=logs',
    '--exclude=.env.local',
    '--exclude=*.log',
    '--exclude=.DS_Store',
    '--exclude=Thumbs.db'
)

$tarCommand = "tar -czf $ArchiveName $($excludePatterns -join ' ') *"
Write-Host "Running: $tarCommand" -ForegroundColor Gray

try {
    Invoke-Expression $tarCommand
    Write-Host "✅ Archive created successfully: $ArchiveName" -ForegroundColor Green
}
catch {
    Write-Error "Failed to create archive: $_"
    exit 1
}

# Check archive size
$archiveSize = (Get-Item $ArchiveName).Length / 1MB
Write-Host "📊 Archive size: $([math]::Round($archiveSize, 2)) MB" -ForegroundColor Yellow

# Upload to EC2
Write-Host "⬆️ Uploading to EC2..." -ForegroundColor Cyan

$scpCommand = "scp -i `"$KeyPath`" $ArchiveName ubuntu@${EC2IP}:/home/ubuntu/"
Write-Host "Running: $scpCommand" -ForegroundColor Gray

try {
    Invoke-Expression $scpCommand
    Write-Host "✅ Upload completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to upload: $_"
    exit 1
}

# Clean up local archive
Remove-Item $ArchiveName
Write-Host "🧹 Cleaned up local archive" -ForegroundColor Yellow

# Provide next steps
Write-Host "`n🎯 Next Steps:" -ForegroundColor Green
Write-Host "1. Connect to your EC2 instance:" -ForegroundColor White
Write-Host "   ssh -i `"$KeyPath`" ubuntu@$EC2IP" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Extract and deploy:" -ForegroundColor White
Write-Host "   mkdir -p /home/ubuntu/ratecard" -ForegroundColor Cyan
Write-Host "   cd /home/ubuntu/ratecard" -ForegroundColor Cyan
Write-Host "   tar -xzf ../$ArchiveName" -ForegroundColor Cyan
Write-Host "   rm ../$ArchiveName" -ForegroundColor Cyan
Write-Host "   chmod +x deploy-to-aws.sh" -ForegroundColor Cyan
Write-Host "   sudo ./deploy-to-aws.sh" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Access your application:" -ForegroundColor White
Write-Host "   http://$EC2IP" -ForegroundColor Cyan

Write-Host "`n🎉 Upload completed! Your project is ready for deployment on EC2." -ForegroundColor Green
