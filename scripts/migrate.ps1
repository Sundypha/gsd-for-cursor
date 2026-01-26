<#
.SYNOPSIS
    Migrates GSD from Claude Code format to Cursor IDE format.

.DESCRIPTION
    This script automates the conversion of GSD files from the original Claude Code
    format to the Cursor IDE format. It handles:
    - Path reference updates (~/.claude/ → ~/.cursor/)
    - Command name format changes (gsd:cmd → gsd-cmd)
    - Tool name conversions (PascalCase → snake_case)
    - Frontmatter format changes
    - Color name to hex conversions

.PARAMETER SourcePath
    Path to the GSD master repository (Claude Code format)

.PARAMETER OutputPath
    Path where converted files will be written (default: ./src)

.PARAMETER DryRun
    If specified, shows what would be changed without making changes

.EXAMPLE
    .\migrate.ps1 -SourcePath "C:\repos\gsd-master"
    
.EXAMPLE
    .\migrate.ps1 -SourcePath "C:\repos\gsd-master" -DryRun
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\src",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Color mappings
$ColorMap = @{
    "cyan"    = "#00FFFF"
    "red"     = "#FF0000"
    "green"   = "#00FF00"
    "blue"    = "#0000FF"
    "yellow"  = "#FFFF00"
    "magenta" = "#FF00FF"
    "orange"  = "#FFA500"
    "purple"  = "#800080"
    "pink"    = "#FFC0CB"
    "white"   = "#FFFFFF"
    "gray"    = "#808080"
    "grey"    = "#808080"
}

# Tool name mappings (Claude Code → Cursor)
$ToolMap = @{
    "Read"            = "read"
    "Write"           = "write"
    "Edit"            = "edit"
    "Bash"            = "bash"
    "Glob"            = "glob"
    "Grep"            = "grep"
    "Task"            = $null  # Removed - handled differently
    "AskUserQuestion" = "ask_question"
    "TodoWrite"       = "todo_write"
    "WebFetch"        = "web_fetch"
    "WebSearch"       = "web_search"
    "MultiEdit"       = "multi_edit"
}

function Write-Info($message) {
    Write-Host "[INFO] $message" -ForegroundColor Cyan
}

function Write-Change($message) {
    Write-Host "[CHANGE] $message" -ForegroundColor Yellow
}

function Write-Skip($message) {
    Write-Host "[SKIP] $message" -ForegroundColor Gray
}

function Convert-PathReferences {
    param([string]$content)
    
    $content = $content -replace '~/.claude/', '~/.cursor/'
    $content = $content -replace '\.claude/', '.cursor/'
    $content = $content -replace '@~/.claude/get-shit-done/', '@~/.cursor/get-shit-done/'
    $content = $content -replace '\$CLAUDE_PROJECT_DIR', '${workspaceFolder}'
    
    return $content
}

function Convert-CommandReferences {
    param([string]$content)
    
    # Convert /gsd:command to /gsd-command
    $content = $content -replace '/gsd:', '/gsd-'
    
    # Convert name: gsd:command to name: gsd-command in frontmatter
    $content = $content -replace 'name:\s*gsd:', 'name: gsd-'
    
    return $content
}

function Convert-ToolNames {
    param([string]$content)
    
    foreach ($tool in $ToolMap.Keys) {
        if ($ToolMap[$tool]) {
            # In prose/documentation
            $content = $content -replace "\b$tool\b", $ToolMap[$tool]
        }
    }
    
    return $content
}

function Convert-ColorToHex {
    param([string]$content)
    
    foreach ($color in $ColorMap.Keys) {
        $hex = $ColorMap[$color]
        $content = $content -replace "color:\s*$color\b", "color: `"$hex`""
    }
    
    return $content
}

function Convert-CommandFrontmatter {
    param([string]$content)
    
    # Check if this is a command file with allowed-tools
    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $frontmatter = $Matches[1]
        
        # Convert allowed-tools array to tools object
        if ($frontmatter -match 'allowed-tools:') {
            # Extract tools list
            $toolsList = @()
            if ($frontmatter -match '(?s)allowed-tools:\s*\n((?:\s+-\s+\w+\s*\n?)+)') {
                $toolsBlock = $Matches[1]
                $toolsList = [regex]::Matches($toolsBlock, '-\s+(\w+)') | ForEach-Object { $_.Groups[1].Value }
            }
            
            # Build new tools object
            $toolsObject = "tools:`n"
            foreach ($tool in $toolsList) {
                $cursorTool = $ToolMap[$tool]
                if ($cursorTool) {
                    $toolsObject += "  $cursorTool`: true`n"
                }
            }
            
            # Replace in frontmatter
            $newFrontmatter = $frontmatter -replace '(?s)allowed-tools:\s*\n(?:\s+-\s+\w+\s*\n?)+', $toolsObject
            $content = $content -replace [regex]::Escape($frontmatter), $newFrontmatter
        }
    }
    
    return $content
}

function Convert-AgentFrontmatter {
    param([string]$content)
    
    # Check if this is an agent file with comma-separated tools
    if ($content -match '(?s)^---\s*\n(.+?)\n---') {
        $frontmatter = $Matches[1]
        
        # Convert comma-separated tools to tools object
        if ($frontmatter -match 'tools:\s*([A-Z][a-zA-Z,\s]+)(?:\n|$)') {
            $toolsLine = $Matches[1].Trim()
            $toolsList = $toolsLine -split ',\s*'
            
            # Build new tools object
            $toolsObject = "tools:`n"
            foreach ($tool in $toolsList) {
                $tool = $tool.Trim()
                $cursorTool = $ToolMap[$tool]
                if ($cursorTool) {
                    $toolsObject += "  $cursorTool`: true`n"
                }
            }
            
            # Replace in frontmatter
            $newFrontmatter = $frontmatter -replace "tools:\s*$([regex]::Escape($toolsLine))", $toolsObject.TrimEnd()
            $content = $content -replace [regex]::Escape($frontmatter), $newFrontmatter
        }
    }
    
    return $content
}

function Convert-File {
    param(
        [string]$sourcePath,
        [string]$destPath,
        [string]$fileType
    )
    
    $content = Get-Content -Path $sourcePath -Raw -Encoding UTF8
    $originalContent = $content
    
    # Apply conversions based on file type
    $content = Convert-PathReferences $content
    $content = Convert-CommandReferences $content
    $content = Convert-ColorToHex $content
    
    if ($fileType -eq "command") {
        $content = Convert-CommandFrontmatter $content
    }
    elseif ($fileType -eq "agent") {
        $content = Convert-AgentFrontmatter $content
    }
    else {
        $content = Convert-ToolNames $content
    }
    
    if ($content -ne $originalContent) {
        if ($DryRun) {
            Write-Change "Would convert: $sourcePath → $destPath"
        }
        else {
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Set-Content -Path $destPath -Value $content -Encoding UTF8 -NoNewline
            Write-Change "Converted: $sourcePath → $destPath"
        }
        return $true
    }
    else {
        if ($DryRun) {
            Write-Skip "No changes needed: $sourcePath"
        }
        else {
            $destDir = Split-Path -Parent $destPath
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Info "Copied unchanged: $sourcePath → $destPath"
        }
        return $false
    }
}

function Main {
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  GSD Migration: Claude Code → Cursor" -ForegroundColor Green
    Write-Host "========================================`n" -ForegroundColor Green
    
    if (-not (Test-Path $SourcePath)) {
        Write-Host "ERROR: Source path not found: $SourcePath" -ForegroundColor Red
        exit 1
    }
    
    if ($DryRun) {
        Write-Host "DRY RUN MODE - No files will be modified`n" -ForegroundColor Magenta
    }
    
    $stats = @{
        Converted = 0
        Copied = 0
        Errors = 0
    }
    
    # Process commands
    Write-Info "Processing commands..."
    $commandsPath = Join-Path $SourcePath "commands\gsd"
    if (Test-Path $commandsPath) {
        Get-ChildItem -Path $commandsPath -Filter "*.md" | ForEach-Object {
            $destPath = Join-Path $OutputPath "commands\gsd\$($_.Name)"
            try {
                if (Convert-File -sourcePath $_.FullName -destPath $destPath -fileType "command") {
                    $stats.Converted++
                } else {
                    $stats.Copied++
                }
            }
            catch {
                Write-Host "ERROR processing $($_.Name): $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
    }
    
    # Process agents
    Write-Info "`nProcessing agents..."
    $agentsPath = Join-Path $SourcePath "agents"
    if (Test-Path $agentsPath) {
        Get-ChildItem -Path $agentsPath -Filter "gsd-*.md" | ForEach-Object {
            $destPath = Join-Path $OutputPath "agents\$($_.Name)"
            try {
                if (Convert-File -sourcePath $_.FullName -destPath $destPath -fileType "agent") {
                    $stats.Converted++
                } else {
                    $stats.Copied++
                }
            }
            catch {
                Write-Host "ERROR processing $($_.Name): $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
    }
    
    # Process workflows
    Write-Info "`nProcessing workflows..."
    $workflowsPath = Join-Path $SourcePath "get-shit-done\workflows"
    if (Test-Path $workflowsPath) {
        Get-ChildItem -Path $workflowsPath -Filter "*.md" | ForEach-Object {
            $destPath = Join-Path $OutputPath "workflows\$($_.Name)"
            try {
                if (Convert-File -sourcePath $_.FullName -destPath $destPath -fileType "workflow") {
                    $stats.Converted++
                } else {
                    $stats.Copied++
                }
            }
            catch {
                Write-Host "ERROR processing $($_.Name): $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
    }
    
    # Process templates
    Write-Info "`nProcessing templates..."
    $templatesPath = Join-Path $SourcePath "get-shit-done\templates"
    if (Test-Path $templatesPath) {
        Get-ChildItem -Path $templatesPath -Recurse -File | ForEach-Object {
            $relativePath = $_.FullName.Substring($templatesPath.Length + 1)
            $destPath = Join-Path $OutputPath "templates\$relativePath"
            try {
                if (Convert-File -sourcePath $_.FullName -destPath $destPath -fileType "template") {
                    $stats.Converted++
                } else {
                    $stats.Copied++
                }
            }
            catch {
                Write-Host "ERROR processing $relativePath`: $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
    }
    
    # Process references
    Write-Info "`nProcessing references..."
    $referencesPath = Join-Path $SourcePath "get-shit-done\references"
    if (Test-Path $referencesPath) {
        Get-ChildItem -Path $referencesPath -Filter "*.md" | ForEach-Object {
            $destPath = Join-Path $OutputPath "references\$($_.Name)"
            try {
                if (Convert-File -sourcePath $_.FullName -destPath $destPath -fileType "reference") {
                    $stats.Converted++
                } else {
                    $stats.Copied++
                }
            }
            catch {
                Write-Host "ERROR processing $($_.Name): $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
    }
    
    # Process hooks
    Write-Info "`nProcessing hooks..."
    $hooksPath = Join-Path $SourcePath "hooks"
    if (Test-Path $hooksPath) {
        Get-ChildItem -Path $hooksPath -Filter "gsd-*.js" | ForEach-Object {
            $destPath = Join-Path $OutputPath "hooks\$($_.Name)"
            try {
                if (Convert-File -sourcePath $_.FullName -destPath $destPath -fileType "hook") {
                    $stats.Converted++
                } else {
                    $stats.Copied++
                }
            }
            catch {
                Write-Host "ERROR processing $($_.Name): $_" -ForegroundColor Red
                $stats.Errors++
            }
        }
    }
    
    # Summary
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "  Migration Summary" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Converted: $($stats.Converted)" -ForegroundColor Yellow
    Write-Host "  Copied:    $($stats.Copied)" -ForegroundColor Cyan
    Write-Host "  Errors:    $($stats.Errors)" -ForegroundColor $(if ($stats.Errors -gt 0) { "Red" } else { "Green" })
    Write-Host "========================================`n" -ForegroundColor Green
    
    if ($DryRun) {
        Write-Host "This was a DRY RUN. Run without -DryRun to apply changes.`n" -ForegroundColor Magenta
    }
    else {
        Write-Host "Migration complete! Review changes and run verification.`n" -ForegroundColor Green
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  1. Review converted files in: $OutputPath" -ForegroundColor White
        Write-Host "  2. Run verification: Select-String -Path '$OutputPath\**\*.md' -Pattern '\.claude' -Recurse" -ForegroundColor White
        Write-Host "  3. Test installation: .\install.ps1" -ForegroundColor White
    }
}

Main


