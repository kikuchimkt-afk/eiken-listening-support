# STEP1_CreateNewFolder.ps1
# Tool to create a new project folder automatically.

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetsDir = Join-Path $rootDir "assets"

Write-Host "=========================================="
Write-Host "  Eiken App: Create New Project Folder"
Write-Host "=========================================="
Write-Host ""

# 1. Level
$levelInput = Read-Host "Level? (Enter number: 3, 4, 5, or pre2)"
if ([string]::IsNullOrWhiteSpace($levelInput)) {
    Write-Host "Canceled."
    exit
}
$levelDirName = "level" + $levelInput

# 2. Year
$yearInput = Read-Host "Year? (e.g. 2024)"
if ([string]::IsNullOrWhiteSpace($yearInput)) { $yearInput = Get-Date -Format "yyyy" }

# 3. Session
$sessionInput = Read-Host "Session? (1, 2, or 3)"
if ([string]::IsNullOrWhiteSpace($sessionInput)) { $sessionInput = "1" }

# Build Path
$targetDirName = "$yearInput-$sessionInput"
$targetPath = Join-Path $assetsDir $levelDirName
$targetPath = Join-Path $targetPath $targetDirName

# Create Dir
if (-not (Test-Path -Path $targetPath)) {
    New-Item -ItemType Directory -Force -Path $targetPath | Out-Null
    Write-Host ""
    Write-Host "Success: Folder created!" -ForegroundColor Green
    Write-Host "Path: $targetPath"
}
else {
    Write-Host ""
    Write-Host "Info: Folder already exists." -ForegroundColor Yellow
    Write-Host "Path: $targetPath"
}

Write-Host ""
Write-Host "------------------------------------------"
Write-Host "[IMPORTANT] Please do the following in the opened folder:"
Write-Host "1. Put all your MP3 files here."
Write-Host "2. Save your 'data.json' file here."
Write-Host "------------------------------------------"
Write-Host ""
Write-Host "Press Enter to open the folder..."
$null = Read-Host

# Open Explorer
Invoke-Item $targetPath
