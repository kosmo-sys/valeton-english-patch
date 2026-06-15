# GP-5 PatchToEnglish v1.0.6
# Translates GP-5 firmware from Chinese to English
# License: OpenCode

param(
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$OutputFolder = $ScriptDir

$InputFile = $null
$OutputFile = $null
$ForcePatch = $false
$Region = $null
$ShowHelp = $false
$ShowMan = $false

$i = 0
while ($i -lt $Arguments.Count) {
    $arg = $Arguments[$i]
    switch -Regex ($arg) {
        '^-input$' { $InputFile = $Arguments[++$i] }
        '^-output$' { $OutputFile = $Arguments[++$i] }
        '^-r$' { 
            $Region = @($Arguments[++$i], $Arguments[++$i])
        }
        '^--force-patch$' { $ForcePatch = $true }
        '^--help$' { $ShowHelp = $true }
        '^--man$' { $ShowMan = $true }
        '^-input(.+)' { $InputFile = $Matches[1] }
        '^-output(.+)' { $OutputFile = $Matches[1] }
        '^-r(.+)' { 
            $parts = $Matches[1] -split '\s+'
            $Region = @($parts[0], $parts[1])
        }
        '^--force-patch$' { $ForcePatch = $true }
    }
    $i++
}

function Show-Help {
    Write-Host @"
GP-5 PatchToEnglish v1.0.6
==========================

USAGE:
    .\GP-5-PatchToEnglish-v1_0_6.ps1 -input <firmware> [-output <output>] [OPTIONS]

OPTIONS:
    -input <file>          Input firmware file (required)
    -output <file>         Output firmware file (default: <input>-PatchedToEnglish-v1_0_6.bin)
    -r <start> <end>    Custom hex region to patch (e.g., -r 0x162378 0x1624B0)
    --force-patch       Skip version validation
    --help              Show this help message
    --man               Show detailed manual

EXAMPLES:
    .\GP-5-PatchToEnglish-v1_0_6.ps1 -input "GP-5 Firmware V1.0.6.bin"
    .\GP-5-PatchToEnglish-v1_0_6.ps1 -input firm.bin -output patchfirm.bin --force-patch
    .\GP-5-PatchToEnglish-v1_0_6.ps1 -input firm.bin -r 0x162378 0x1624B0

OUTPUT:
    Patched firmware saved to input folder
    Output filename: <original>-PatchedToEnglish-v1_0_6.bin (or custom -output)

"@ -ForegroundColor Cyan
    exit 0
}

function Show-Man {
    Write-Host @"
GP-5 PatchToEnglish v1.0.6 - Detailed Manual
============================================

DESCRIPTION:
    This script translates the GP-5 guitar processor firmware from Chinese
    to English by replacing Chinese text strings with English equivalents
    while preserving the original byte boundaries and structure.

    This tool is intended for educational purposes and right-to-repair
    advocacy. Users must obtain the original firmware legally.

VERSION CHECK:
    The script validates that the input firmware is version V1.0.6 by
    searching for the "V106" string at offset 0x90. If a different
    version is detected, patching will be refused unless --force-patch
    is used.

OPTIONS:
    -input <file>
        Path to the original firmware .bin file. Required.

    -output <file>
        Output path for patched firmware. If not specified, defaults to
        <input_name>-PatchedToEnglish-v1_0_6.bin in the same folder as input.

    -r <start> <end>
        Custom hex region to patch. Default is 0x162378 to 0x1624B0.
        Specify start and end addresses in hexadecimal format.
        Example: -r 0x162378 0x1624B0

    --force-patch
        Skip version validation. WARNING: This may corrupt firmware
        if the version is incompatible. Use at your own risk.

    --help
        Display brief usage information.

    --man
        Display this detailed manual.

OUTPUT FILES:
    The patched firmware is saved to the specified output path, or to
    the same folder as the input file with -PatchedToEnglish-v1_0_6.bin suffix.

TECHNICAL DETAILS:
    - Scans for UTF-8 encoded Chinese strings in the specified region
    - Replaces each Chinese string with English translation
    - Uses dynamic length calculation based on next string position
    - Preserves null-byte padding to maintain structure
    - All replacements stay within original byte boundaries

SUPPORTED TRANSLATIONS:
    - Menu items and navigation
    - Parameter names and labels
    - Status messages and notifications
    - Error messages and warnings
    - Factory reset messages
    - And more...

LANGUAGE:
    PowerShell (Windows)

COMPATIBILITY:
    - Windows PowerShell 5.1+
    - PowerShell Core 7+

LICENSE:
    This script is licensed under the OpenCode License.

SEE ALSO:
    Project repository for updates and documentation

"@ -ForegroundColor Cyan
    exit 0
}

if ($ShowHelp) { Show-Help }
if ($ShowMan) { Show-Man }

if (-not $InputFile) {
    Write-Host "ERROR: Input file required. Use -input <firmware.bin>" -ForegroundColor Red
    Write-Host "Run with --help for usage information" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path $InputFile)) {
    Write-Host "ERROR: File not found: $InputFile" -ForegroundColor Red
    exit 1
}

$VersionOffset = 0x90
$ExpectedVersion = "V106"

$fileBytes = [System.IO.File]::ReadAllBytes($InputFile)

if ($fileBytes.Length -lt $VersionOffset + 4) {
    Write-Host "ERROR: File too small to be valid firmware" -ForegroundColor Red
    exit 1
}

$detectedVersion = [System.Text.Encoding]::ASCII.GetString($fileBytes[$VersionOffset..($VersionOffset + 3)])

if ($detectedVersion -ne $ExpectedVersion -and -not $ForcePatch) {
    Write-Host "ERROR: This firmware is not V1.0.6." -ForegroundColor Red
    Write-Host "Found version string: $detectedVersion" -ForegroundColor Yellow
    Write-Host "Expected: $ExpectedVersion" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Use --force-patch to attempt patching anyway (may corrupt firmware)" -ForegroundColor Yellow
    exit 1
}

if ($ForcePatch) {
    Write-Host "WARNING: Version validation skipped (--force-patch)" -ForegroundColor Yellow
    Write-Host "Detected version: $detectedVersion" -ForegroundColor Yellow
}

$searchStart = 0x162180
$searchEnd = 0x1625D0

if ($Region) {
    try {
        $searchStart = [int64]$Region[0]
        $searchEnd = [int64]$Region[1]
    } catch {
        Write-Host "ERROR: Invalid hex address format" -ForegroundColor Red
        exit 1
    }
}

if (-not $OutputFile) {
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    $InputDir = Split-Path -Parent $InputFile
    if ($InputDir) {
$OutputFile = Join-Path $InputDir "$baseName-PatchedToEnglish-v1_0_6.bin"
    } else {
        $OutputFile = "$baseName-PatchedToEnglish-v1_0_6.bin"
    }
}

Write-Host "GP-5 PatchToEnglish v1.0.6" -ForegroundColor Cyan
Write-Host "==========================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Input:   $InputFile"
Write-Host "Output:  $OutputFile"
Write-Host "Region: 0x$($searchStart.ToString('X')) to 0x$($searchEnd.ToString('X'))"
Write-Host ""

$utf8 = [System.Text.Encoding]::UTF8

$mapping = @{}

$mapping[$utf8.GetString([byte[]](0xE8,0xBF,0x94,0xE5,0x9B,0x9E))] = "BACK"
$mapping[$utf8.GetString([byte[]](0xE8,0xBE,0x93,0xE5,0x85,0xA5,0x0A,0xE7,0x94,0xB5,0xE5,0xB9,0xB3))] = "Input`nLevel"
$mapping[$utf8.GetString([byte[]](0xE6,0x97,0xA0,0xE7,0xAE,0xB1,0xE4,0xBD,0x93))] = "Cab"
$mapping[$utf8.GetString([byte[]](0xE5,0xBC,0x80,0xE5,0x90,0xAF))] = "ON"
$mapping[$utf8.GetString([byte[]](0xE5,0x85,0xB3,0xE9,0x97,0xAD))] = "OFF"
$mapping[$utf8.GetString([byte[]](0xE8,0xB8,0xA9,0xE9,0x92,0x89,0x0A,0xE6,0xA8,0xA1,0xE5,0xBC,0x8F))] = " FS `nMode"
$mapping[$utf8.GetString([byte[]](0xE5,0xBD,0x95,0xE5,0x88,0xB6,0x0A,0xE9,0x9F,0xB3,0xE9,0x87,0x8F))] = " REC`nLevel"
$mapping[$utf8.GetString([byte[]](0xE5,0xBD,0x95,0xE5,0x88,0xB6))] = "REC"
$mapping[$utf8.GetString([byte[]](0xE7,0x9B,0x91,0xE5,0x90,0xAC,0x0A,0xE9,0x9F,0xB3,0xE9,0x87,0x8F))] = " Mon`nLevel"
$mapping[$utf8.GetString([byte[]](0xE8,0xAF,0xAD,0xE8,0xA8,0x80))] = "LANG"
$mapping[$utf8.GetString([byte[]](0xE6,0x81,0xA2,0xE5,0xA4,0x8D))] = "Reset"
$mapping[$utf8.GetString([byte[]](0xE5,0x85,0xB3,0xE4,0xBA,0x8E))] = "About"
$mapping[$utf8.GetString([byte[]](0xE6,0xA8,0xA1,0xE6,0x8B,0x9F))] = "Analog"
$mapping[$utf8.GetString([byte[]](0xE6,0x95,0xB0,0xE5,0xAD,0x97))] = "Digital"
$mapping[$utf8.GetString([byte[]](0xE6,0x97,0x81,0xE9,0x80,0x9A))] = "Bypass"
$mapping[$utf8.GetString([byte[]](0xE8,0xB0,0x83,0xE9,0x9F,0xB3,0xE8,0xA1,0xA8))] = "Tuner"
$mapping[$utf8.GetString([byte[]](0xE7,0xA1,0xAE,0xE5,0xAE,0x9A,0xE8,0xA6,0x81,0xE6,0x81,0xA2,0xE5,0xA4,0x8D,0xE5,0x87,0xBA,0xE5,0x8E,0x82,0xE5,0x90,0x97,0x3F))] = "Factory reset?"
$mapping[$utf8.GetString([byte[]](0xE6,0x81,0xA2,0xE5,0xA4,0x8D,0xE4,0xB8,0xAD,0x2E,0x2E,0x2E))] = "Resetting..."
$mapping[$utf8.GetString([byte[]](0xE6,0x81,0xA2,0xE5,0xA4,0x8D,0xE5,0xAE,0x8C,0xE6,0x88,0x90))] = "Reset complete"
$mapping[$utf8.GetString([byte[]](0x20,0x20,0xE7,0x89,0x88,0xE6,0x9C,0xAC,0x3A,0x20))] = "   FW: "
$mapping[$utf8.GetString([byte[]](0xC2,0xA9,0x56,0x61,0x6C,0x65,0x74,0x6F,0x6E,0xE7,0x89,0x88,0xE6,0x9D,0x83,0xE6,0x89,0x80,0xE6,0x9C,0x89))] = "KosmosysMod"
$mapping[$utf8.GetString([byte[]](0xE9,0x9D,0x99,0xE9,0x9F,0xB3))] = "Mute"
$mapping[$utf8.GetString([byte[]](0xE6,0x95,0xB0,0xE5,0xAD,0x97,0xE6,0x97,0x81,0xE9,0x80,0x9A))] = "DSP Bypass"
$mapping[$utf8.GetString([byte[]](0xE6,0xA8,0xA1,0xE6,0x8B,0x9F,0xE6,0x97,0x81,0xE9,0x80,0x9A))] = "Ana Bypass"

Write-Host "Loaded $($mapping.Count) translations" -ForegroundColor Cyan
Write-Host "Scanning for strings..." -ForegroundColor Cyan

$allStrings = @()
$i = $searchStart
while ($i -lt $searchEnd - 1) {
    if ($fileBytes[$i] -ge 0x20 -and $fileBytes[$i] -ne 0xFF) {
        $strStart = $i
        while ($i -lt $searchEnd -and $fileBytes[$i] -ne 0x00) { $i++ }
        $strEnd = $i
        $strBytes = $fileBytes[$strStart..($strEnd-1)]
        if ($strBytes.Length -gt 0) {
            $allStrings += @{
                offset = $strStart
                length = $strEnd - $strStart
                end = $strEnd
            }
        }
    }
    $i++
}

Write-Host "Found $($allStrings.Count) strings in region" -ForegroundColor Yellow

$patched = 0
$failed = 0

for ($s = 0; $s -lt $allStrings.Count; $s++) {
    $current = $allStrings[$s]
    $strBytes = $fileBytes[$current.offset..($current.offset + $current.length - 1)]
    $decoded = $utf8.GetString($strBytes)
    
    $hasChinese = $false
    foreach ($b in $strBytes) { if ($b -ge 0xE4) { $hasChinese = $true; break } }
    
    if ($hasChinese -and $mapping.ContainsKey($decoded)) {
        if ($s -lt ($allStrings.Count - 1)) {
            $nextOffset = $allStrings[$s + 1].offset
        } else {
            $nextOffset = $searchEnd
        }
        
        $availableSpace = $nextOffset - $current.offset
        $english = $mapping[$decoded]
        $engBytes = [System.Text.Encoding]::ASCII.GetBytes($english + "`0")
        $engLen = $engBytes.Count
        
        if ($engLen -le $availableSpace) {
            for ($j = 0; $j -lt $availableSpace; $j++) {
                if ($j -lt $engLen) {
                    $fileBytes[$current.offset + $j] = $engBytes[$j]
                } else {
                    $fileBytes[$current.offset + $j] = 0x00
                }
            }
            $patched++
        } else {
            Write-Host "SKIPPED (too long): $english ($engLen > $availableSpace bytes)" -ForegroundColor Red
            $failed++
        }
    }
}

Write-Host ""
Write-Host "Patched: $patched strings" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "Failed: $failed strings (too long for available space)" -ForegroundColor Red
}

[System.IO.File]::WriteAllBytes($OutputFile, $fileBytes)

Write-Host ""
Write-Host "Done! Output saved to: $OutputFile" -ForegroundColor Cyan
