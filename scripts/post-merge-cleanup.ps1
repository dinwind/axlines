# Mandatory post-merge cleanup: return to trunk and delete local + remote head.
# Prefer: co branch cleanup <branch>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Branch
)

$ErrorActionPreference = "Stop"
co branch cleanup $Branch
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
