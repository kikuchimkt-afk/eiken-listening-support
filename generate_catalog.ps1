# Generate projects_catalog.json automatically
# Run this script before uploading to server.

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$assetsDir = Join-Path $rootDir "assets"
$outputFile = Join-Path $rootDir "projects_catalog.json"

$catalog = @()

# Find all JSON files in assets subdirectories
$projectFiles = Get-ChildItem -Path $assetsDir -Recurse -Filter "*.json"

foreach ($file in $projectFiles) {
    # Skip the catalog itself if it accidentally got into assets (unlikely but safe)
    if ($file.Name -eq "projects_catalog.json") { continue }

    $dir = $file.DirectoryName
    $relativeDir = $dir.Substring($rootDir.Length + 1).Replace("\", "/")
    
    # Read JSON content to get markers info
    try {
        $jsonContent = Get-Content $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $markers = $jsonContent.markers
        $title = "英検プロジェクト (" + $file.Directory.Name + ")"
        
        # Determine Title from directory structure (e.g., assets/level4/2025-2 -> 2025-2 Level4)
        $parts = $relativeDir -split "/"
        if ($parts.Count -ge 3) {
           $title = $parts[-1] + " " + $parts[-2] # 2025-2 level4
        }
    } catch {
        Write-Host "Error reading $($file.Name): $_"
        continue
    }

    # Find Audio files in the same directory
    $audioFiles = Get-ChildItem -Path $dir -Filter "*.mp3"
    $audioConfig = @()

    foreach ($audio in $audioFiles) {
        $name = $audio.Name
        $partNum = 1
        $rangeStart = 1
        $rangeEnd = 100

        # Heuristic: Try to guess Part number and Range from filename
        # Pattern: "part1", "part 1", "No.1-10"
        if ($name -match "part(\d+)" -or $name -match "Part(\d+)") {
            $partNum = [int]$matches[1]
            
            # Default logic: Part 1 = 1-10, Part 2 = 11-20, Part 3 = 21-30
            # This works for Level 4 and 3 mostly.
            $rangeStart = ($partNum - 1) * 10 + 1
            $rangeEnd = $partNum * 10
        }
        elseif ($name -match "(\d+)-(\d+)") {
             # if filename is like "No.1-10.mp3"
             $rangeStart = [int]$matches[1]
             $rangeEnd = [int]$matches[2]
             $partNum = 1 # Treat as single part covering this range
        }

        $audioConfig += @{
            part = $partNum
            range = @($rangeStart, $rangeEnd)
            file = $audio.Name
            label = $audio.Name.Replace(".mp3", "")
        }
    }
    
    # Sort audio by range start
    $audioConfig = $audioConfig | Sort-Object { $_.range[0] }

    $catalog += @{
        id = $dir.Name + "_" + $file.BaseName # Unique ID based on folder
        title = $title
        dir = $relativeDir
        json = $file.Name
        audio = $audioConfig
    }
}

# Convert to JSON with pretty print
$jsonOutput = $catalog | ConvertTo-Json -Depth 4
Set-Content -Path $outputFile -Value $jsonOutput -Encoding UTF8

Write-Host "Success! Created projects_catalog.json with $($catalog.Count) projects."
Write-Host "Path: $outputFile"
