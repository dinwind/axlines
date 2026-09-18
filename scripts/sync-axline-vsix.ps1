# Sync the Axline built-in extension (.vsix) from the AuthNexus share link.
#
# Called before compiling/packaging to ensure the embedded Axline extension is
# the latest published version. Flow:
#   1. Query the public AuthNexus share API for the latest release metadata
#      (version, fileHash) - no login required.
#   2. Compare against the local .vsix (by sha256).
#   3. If outdated/missing, download and replace the local .vsix.
#   4. Optionally update product.json (version + sha256) so the build embeds
#      the matching artifact.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\sync-axline-vsix.ps1
#   powershell ... -UpdateProductJson   (also keep product.json axline.axline entry in sync)
#
param(
    [string]$Token        = "lHj0ZFT8JJub6_KVo12hifkgUlR1liW0",
    [string]$VsixPath     = "",                                # defaults to <repo>\scripts\axline.vsix
    [switch]$UpdateProductJson,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# --- Paths ---------------------------------------------------------------
$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot     = Split-Path -Parent $ScriptDir
if (-not $VsixPath) {
    $VsixPath = Join-Path $ScriptDir "axline.vsix"
}
$VsixPath     = [System.IO.Path]::GetFullPath($VsixPath)
$ProductJson  = Join-Path $RepoRoot "product.json"

# --- Constants ------------------------------------------------------------
$BaseUrl      = "https://auth.mtsilicon.com/api/public/releases/share"
$MetaUrl      = "$BaseUrl/$Token"
$DownloadUrl  = "$BaseUrl/$Token/download"
$ExtensionKey = "axline.axline"   # matches the name field in product.json builtInExtensions

function Write-Step($msg) { Write-Host "[axline-vsix] $msg" }

# Pure .NET SHA256 (no dependency on the Get-FileHash cmdlet, which is not
# guaranteed to auto-load under the constrained PSModulePath used by build.bat).
function Get-Sha256 {
    param([string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            return ([System.BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLower()
        }
        finally {
            $sha.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

# --- 1. Fetch latest metadata --------------------------------------------
Write-Step "Fetching latest release metadata from AuthNexus..."
try {
    $meta = Invoke-RestMethod -Uri $MetaUrl -Headers @{ Accept = "application/json" } -Method Get
}
catch {
    Write-Host "[ERROR] Failed to query $MetaUrl : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if (-not $meta -or -not $meta.version) {
    Write-Host "[ERROR] Share link returned no version. The link may be revoked or invalid." -ForegroundColor Red
    exit 1
}

$latestVersion = [string]$meta.version
$latestHash    = [string]$meta.fileHash
$fileName      = if ($meta.fileDisplayName) { [string]$meta.fileDisplayName } else { "axline.vsix" }
$fileSize      = [string]$meta.fileSize

Write-Step ("Latest  : {0}  (sha256={1}, {2} bytes, file={3})" -f $latestVersion, $latestHash, $fileSize, $fileName)

# --- 2. Compare local vsix ------------------------------------------------
$localHash = $null
if (Test-Path $VsixPath) {
    $localHash = Get-Sha256 -Path $VsixPath
    Write-Step ("Local   : sha256={0}  ({1})" -f $localHash, $VsixPath)
}
else {
    Write-Step "Local   : missing  ($VsixPath)"
}

$needsDownload = $Force -or (-not $localHash) -or ($localHash -ne $latestHash.ToLower())

if (-not $needsDownload) {
    Write-Step "Up to date - nothing to do."
    exit 0
}

# --- 3. Download and replace ----------------------------------------------
if ($Force) {
    Write-Step "Forced refresh. Downloading .vsix..."
}
elseif ($localHash) {
    Write-Step "Update available (hash differs). Downloading new .vsix..."
}
else {
    Write-Step "No local .vsix. Downloading..."
}

$tmp = "$VsixPath.tmp"
try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $tmp -UseBasicParsing
}
catch {
    Write-Host "[ERROR] Download failed: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
    exit 1
}

# Verify downloaded hash matches the published fileHash before replacing the local file.
$dlHash = Get-Sha256 -Path $tmp
if ($dlHash -ne $latestHash.ToLower()) {
    Write-Host "[ERROR] Downloaded file sha256 mismatch (expected $latestHash, got $dlHash). Aborting without replacing." -ForegroundColor Red
    Remove-Item $tmp -Force
    exit 1
}

if (Test-Path $VsixPath) { Remove-Item $VsixPath -Force }
Move-Item $tmp $VsixPath
Write-Step ("Saved   : {0} ({1} bytes)" -f $VsixPath, (Get-Item $VsixPath).Length)

# --- 4. Optionally sync product.json -------------------------------------
# Uses targeted string patching (not ConvertTo-Json round-trip) so the rest of
# product.json (formatting, key order, unrelated fields) is never touched.
if ($UpdateProductJson) {
    if (-not (Test-Path $ProductJson)) {
        Write-Host "[ERROR] product.json not found: $ProductJson" -ForegroundColor Red
        exit 1
    }

    $raw = [System.IO.File]::ReadAllText($ProductJson)

    # Locate the builtInExtensions entry named "axline.axline".
    $nameEsc = [regex]::Escape($ExtensionKey)
    $namePattern = '"name"\s*:\s*"' + $nameEsc + '"'
    $nameMatch  = [regex]::Match($raw, $namePattern)
    if (-not $nameMatch.Success) {
        Write-Host "[ERROR] product.json has no builtInExtensions entry named '$ExtensionKey'." -ForegroundColor Red
        exit 1
    }

    $blockStart = $raw.LastIndexOf('{', $nameMatch.Index)
    if ($blockStart -lt 0) {
        Write-Host "[ERROR] Could not locate the '$ExtensionKey' entry object in product.json." -ForegroundColor Red
        exit 1
    }
    $blockEnd = $raw.IndexOf('}', $nameMatch.Index)
    if ($blockEnd -lt 0) {
        Write-Host "[ERROR] Malformed '$ExtensionKey' entry in product.json." -ForegroundColor Red
        exit 1
    }
    $block = $raw.Substring($blockStart, $blockEnd - $blockStart + 1)

    $changed = $false

    # Patch version
    if ($block -notmatch ('"version"\s*:\s*"' + [regex]::Escape($latestVersion) + '"')) {
        $newBlock = [regex]::Replace($block, '("version"\s*:\s*")[^"]*(")', ('${1}' + $latestVersion + '${2}'))
        if ($newBlock -ne $block) {
            $block = $newBlock
            $changed = $true
            Write-Step "product.json version: -> $latestVersion"
        }
    }

    # Patch sha256
    $wantHash = $latestHash.ToLower()
    if ($block -notmatch ('"sha256"\s*:\s*"' + [regex]::Escape($wantHash) + '"')) {
        $newBlock = [regex]::Replace($block, '("sha256"\s*:\s*")[^"]*(")', ('${1}' + $wantHash + '${2}'))
        if ($newBlock -ne $block) {
            $block = $newBlock
            $changed = $true
            Write-Step "product.json sha256 : -> $wantHash"
        }
    }

    if ($changed) {
        $raw = $raw.Remove($blockStart, $blockEnd - $blockStart + 1).Insert($blockStart, $block)
        [System.IO.File]::WriteAllText($ProductJson, $raw)
        Write-Step "product.json updated."
    }
    else {
        Write-Step "product.json already in sync."
    }
}

Write-Step "Done."
exit 0