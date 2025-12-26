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
    
    $gradeSort = 999
    $sortYear = 0
    $sortSession = 0
    $pagesCount = 0

    try {
        $jsonContent = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # Calculate Pages Count
        if ($jsonContent.pages) {
            $pagesCount = $jsonContent.pages.Count
        }
        
        # Generate Title (Use English Only to avoid encoding issues completely)
        $parts = $relativeDir -split "/"
        $title = "Project"
        
        if ($parts.Count -ge 3) {
            # level3 -> 3, levelpre2 -> pre2
            $levelDir = $parts[-2]
            $levelStr = $levelDir.Replace("level", "")
            
            # Grade Name Mapping & Sort Order
            if ($levelStr -eq "1") { $gradeSort = 10 }
            elseif ($levelStr -eq "pre1") { $levelStr = "Pre-1"; $gradeSort = 20 }
            elseif ($levelStr -eq "2") { $gradeSort = 30 }
            elseif ($levelStr -eq "pre2plus") { $levelStr = "Pre-2 Plus"; $gradeSort = 35 }
            elseif ($levelStr -eq "pre2") { $levelStr = "Pre-2"; $gradeSort = 40 }
            elseif ($levelStr -eq "3") { $gradeSort = 50 }
            elseif ($levelStr -eq "4") { $gradeSort = 60 }
            elseif ($levelStr -eq "5") { $gradeSort = 70 }

            $yearPart = $parts[-1]
           
            if ($yearPart -match "(\d{4})-(\d+)") {
                $y = [int]$matches[1]
                $s = [int]$matches[2]
                $sortYear = $y
                $sortSession = $s
                # "2024 Session 1 Eiken Grade 3"
                $title = "{0} Session {1} Eiken Grade {2}" -f $y, $s, $levelStr
            }
            else {
                # Fallback if no session
                $title = "{0} Eiken Grade {1}" -f $yearPart, $levelStr
                if ($yearPart -match "(\d{4})") { $sortYear = [int]$matches[1] }
            }
        }
        
        # Use title from JSON if available (Allow manual override)
        if ($jsonContent.title -and $jsonContent.title -ne "") {
            $title = $jsonContent.title
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

    $catalog += [PSCustomObject]@{
        id         = $uniqueId
        title      = $title
        dir        = $relativeDir
        json       = $file.Name
        audio      = $audioConfig
        pagesCount = $pagesCount
        
        # Internal fields for sorting
        gradeSort  = $gradeSort
        year       = $sortYear
        session    = $sortSession
    }
    
    Write-Host "Target: $title (Pages: $pagesCount)" -ForegroundColor Cyan
}

# Sort Catalog: Grade ASC, Year DESC, Session DESC
$catalog = $catalog | Sort-Object gradeSort, @{Expression = "year"; Descending = $true }, @{Expression = "session"; Descending = $true }

# Save JSON
$jsonOutput = $catalog | ConvertTo-Json -Depth 4
Set-Content -Path $outputFile -Value $jsonOutput -Encoding UTF8

Write-Host ""
Write-Host "Success! Total: $($catalog.Count)" -ForegroundColor Green
Write-Host "Press Enter to exit..."
$null = Read-Host
