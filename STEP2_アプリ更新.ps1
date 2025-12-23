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
        
        # Generate Title (Use English Only to avoid encoding issues completely)
        $parts = $relativeDir -split "/"
        $title = "Project"
        
        if ($parts.Count -ge 3) {
            # level3 -> 3, levelpre2 -> pre2
            $levelStr = $parts[-2].Replace("level", "")
            if ($levelStr -eq "pre2") { $levelStr = "Pre-2" }
           
            $yearPart = $parts[-1]
           
            if ($yearPart -match "(\d{4})-(\d+)") {
                $y = $matches[1]
                $s = $matches[2]
                # "2024 Session 1 Eiken Grade 3"
                $title = "{0} Session {1} Eiken Grade {2}" -f $y, $s, $levelStr
            }
            else {
                $title = "{0} Eiken Grade {1}" -f $yearPart, $levelStr
            }
        }
    }
    catch {
        Write-Host "Skip: $($file.Name)"
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

        # Parse part from filename (simple regex)
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
    
    Write-Host "Target: $title" -ForegroundColor Cyan
}

# Save JSON
$jsonOutput = $catalog | ConvertTo-Json -Depth 4
Set-Content -Path $outputFile -Value $jsonOutput -Encoding UTF8

Write-Host ""
Write-Host "Success! Total: $($catalog.Count)" -ForegroundColor Green
Write-Host "Press Enter to exit..."
$null = Read-Host
