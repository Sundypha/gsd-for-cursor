<#
.SYNOPSIS
    Installs GSD for Cursor IDE to ~/.cursor/

.DESCRIPTION
    This script installs the GSD (Get Shit Done) system for Cursor IDE by
    copying all necessary files to the ~/.cursor/ directory.

.PARAMETER SourcePath
    Path to the cursor-gsd/src directory (default: ./src relative to script)

.PARAMETER Force
    Overwrite existing installation without prompting

.EXAMPLE
    .\install.ps1
    
.EXAMPLE
    .\install.ps1 -Force
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$SourcePath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Determine paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($SourcePath)) {
    $SourcePath = Join-Path $ScriptDir "..\src"
}

$CursorDir = Join-Path $env:USERPROFILE ".cursor"

# Validate CursorDir path
if ([string]::IsNullOrEmpty($env:USERPROFILE)) {
    Write-Host "ERROR: USERPROFILE environment variable is not set." -ForegroundColor Red
    Write-Host "Falling back to HOME or manual path." -ForegroundColor Yellow
    if ($env:HOME) {
        $CursorDir = Join-Path $env:HOME ".cursor"
    } else {
        Write-Host "ERROR: Cannot determine user home directory." -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  GSD Installer for Cursor IDE" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Paths:" -ForegroundColor Cyan
Write-Host "  Source:      $SourcePath" -ForegroundColor Gray
Write-Host "  Target:      $CursorDir" -ForegroundColor Gray
Write-Host ""

# Check source exists
if (-not (Test-Path $SourcePath)) {
    Write-Host "ERROR: Source path not found: $SourcePath" -ForegroundColor Red
    Write-Host "Run the migration script first to generate the src directory." -ForegroundColor Yellow
    exit 1
}

# Check for existing installation
$existingGSD = Join-Path $CursorDir "get-shit-done"
if ((Test-Path $existingGSD) -and -not $Force) {
    Write-Host "Existing GSD installation found at: $existingGSD" -ForegroundColor Yellow
    $response = Read-Host "Overwrite? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        Write-Host "Installation cancelled." -ForegroundColor Cyan
        exit 0
    }
}

# Create directory structure
Write-Host "Creating directory structure..." -ForegroundColor Cyan

$directories = @(
    "commands\gsd",
    "agents",
    "get-shit-done\workflows",
    "get-shit-done\templates",
    "get-shit-done\templates\codebase",
    "get-shit-done\templates\research-project",
    "get-shit-done\references",
    "hooks",
    "cache"
)

foreach ($dir in $directories) {
    $fullPath = Join-Path $CursorDir $dir
    if (-not (Test-Path $fullPath)) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Gray
    }
}

# Copy files
Write-Host "`nCopying files..." -ForegroundColor Cyan

$fileMappings = @(
    @{ Source = "commands\gsd"; Dest = "commands\gsd" },
    @{ Source = "agents"; Dest = "agents" },
    @{ Source = "workflows"; Dest = "get-shit-done\workflows" },
    @{ Source = "templates"; Dest = "get-shit-done\templates" },
    @{ Source = "references"; Dest = "get-shit-done\references" },
    @{ Source = "hooks"; Dest = "hooks" }
)

$fileCount = 0
foreach ($mapping in $fileMappings) {
    $srcDirRaw = Join-Path $SourcePath $mapping.Source
    $destDir = Join-Path $CursorDir $mapping.Dest
    
    Write-Host "  Processing: $($mapping.Source)" -ForegroundColor Gray
    
    if (Test-Path $srcDirRaw) {
        # Resolve to absolute path for correct substring calculation
        $srcDir = (Resolve-Path $srcDirRaw).Path
        
        Write-Host "    srcDir:  $srcDir" -ForegroundColor DarkGray
        Write-Host "    destDir: $destDir" -ForegroundColor DarkGray
        
        Get-ChildItem -Path $srcDir -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($srcDir.Length + 1)
            $destPath = Join-Path $destDir $relativePath
            $destFolder = Split-Path -Parent $destPath
            
            Write-Host "    File: $($_.Name)" -ForegroundColor DarkGray
            Write-Host "      relativePath: $relativePath" -ForegroundColor DarkGray
            Write-Host "      destPath:     $destPath" -ForegroundColor DarkGray
            Write-Host "      destFolder:   $destFolder" -ForegroundColor DarkGray
            
            if (-not (Test-Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
                Write-Host "      Created folder: $destFolder" -ForegroundColor DarkYellow
            }
            
            Copy-Item -Path $_.FullName -Destination $destPath -Force
            Write-Host "      Copied!" -ForegroundColor DarkGreen
            $fileCount++
        }
    } else {
        Write-Host "    srcDir:  $srcDirRaw" -ForegroundColor DarkGray
        Write-Host "    SKIPPED: Source not found" -ForegroundColor DarkYellow
    }
}

# Create or update settings.json
Write-Host "`nConfiguring settings..." -ForegroundColor Cyan

$settingsPath = Join-Path $CursorDir "settings.json"
$settings = @{
    hooks = @{
        SessionStart = @(
            @{
                hooks = @(
                    @{
                        type = "command"
                        command = "node ~/.cursor/hooks/gsd-check-update.js"
                    }
                )
            }
        )
    }
    statusLine = @{
        type = "command"
        command = "node ~/.cursor/hooks/gsd-statusline.js"
    }
}

if (Test-Path $settingsPath) {
    try {
        $existingSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
        # Merge hooks configuration
        if ($existingSettings.hooks) {
            $existingSettings.hooks.SessionStart = $settings.hooks.SessionStart
        } else {
            $existingSettings.hooks = $settings.hooks
        }
        $existingSettings.statusLine = $settings.statusLine
        $settings = $existingSettings
    }
    catch {
        Write-Host "  Warning: Could not parse existing settings.json, creating new one" -ForegroundColor Yellow
    }
}

$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
Write-Host "  Updated: settings.json" -ForegroundColor Gray

# Create VERSION file
$versionPath = Join-Path $CursorDir "get-shit-done\VERSION"
"1.0.0" | Set-Content $versionPath -Encoding UTF8
Write-Host "  Created: VERSION" -ForegroundColor Gray

# Summary
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Installation Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Files installed: $fileCount" -ForegroundColor Cyan
Write-Host "  Location: $CursorDir" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Quick start:" -ForegroundColor Yellow
Write-Host "  1. Open Cursor IDE" -ForegroundColor White
Write-Host "  2. Type /gsd-help to see all commands" -ForegroundColor White
Write-Host "  3. Type /gsd-new-project to start a new project" -ForegroundColor White
Write-Host ""

