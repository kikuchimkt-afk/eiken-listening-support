# STEP2_UpdateApp.ps1
# Tool to update the project catalog (projects_catalog.json).

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetsDir = Join-Path $rootDir "assets"
$outputFile = Join-Path $rootDir "projects_catalog.json"

Write-Host "=========================================="
Write-Host "  Eiken App: Update Catalog"
Write-Host "=========================================="
Write-Host "Scanning folders..."

$catalog = @()

if (-not (Test-Path $assetsDir)) {
    Write-Host "Error: 'assets' folder not found." -ForegroundColor Red
    exit
}

# Find all JSON files in assets subdirectories
$projectFiles = Get-ChildItem -Path $assetsDir -Recurse -Filter "*.json"

foreach ($file in $projectFiles) {
    if ($file.Name -eq "projects_catalog.json") { continue }

    $dir = $file.DirectoryName
    # Relative Path safely
    $relativeDir = $dir.Substring($rootDir.Length + 1).Replace("\", "/")
    
    try {
        $jsonContent = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Generate Title
        # assets/level3/2024-1 -> 2024-1 level3
        $parts = $relativeDir -split "/"
        $title = "Project"
        if ($parts.Count -ge 3) {
            $levelStr = $parts[-2].Replace("level", " Grade ").Replace("pre", "Pre-") 
            $yearStr = $parts[-1].Replace("-", " Session ")
            $title = "$yearStr Eiken $levelStr"
        }
    }
    catch {
        Write-Host "Skip: $($file.Name) (Invalid Format)"
        continue
    }

    # Find Audio
    $audioFiles = Get-ChildItem -Path $dir -Filter "*.mp3"
    $audioConfig = @()

    foreach ($audio in $audioFiles) {
        $name = $audio.Name
        $partNum = 1
        $rangeStart = 1
        $rangeEnd = 100

        # Parse part from filename
        if ($name -match "part(\d+)") {
            $partNum = [int]$matches[1]
            $rangeStart = ($partNum - 1) * 10 + 1
            $rangeEnd = $partNum * 10
        }
        
        $audioConfig += @{
            part  = $partNum
            range = @($rangeStart, $rangeEnd)
            file  = $audio.Name
            label = $audio.Name.Replace(".mp3", "")
        }
    }
    
    $audioConfig = $audioConfig | Sort-Object { $_.range[0] }

    # Unique ID Generation based on relative path
    $uniqueId = $relativeDir.Replace("/", "_").Replace("assets_", "") + "_" + $file.BaseName

    $catalog += @{
        id    = $uniqueId
        title = $title
        dir   = $relativeDir
        json  = $file.Name
        audio = $audioConfig
    }
    
    Write-Host "  OK: $title" -ForegroundColor Cyan
}

# Save JSON
$jsonOutput = $catalog | ConvertTo-Json -Depth 4
Set-Content -Path $outputFile -Value $jsonOutput -Encoding UTF8

Write-Host ""
Write-Host "Success! Total Projects: $($catalog.Count)" -ForegroundColor Green
Write-Host "Press Enter to exit..."
$null = Read-Host
