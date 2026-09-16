# Start a new task branch from latest remote/trunk (Agent Git/PR lifecycle step 1).
# Prefer: co branch start <branch>
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Branch
)

$ErrorActionPreference = "Stop"
co branch start $Branch
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
