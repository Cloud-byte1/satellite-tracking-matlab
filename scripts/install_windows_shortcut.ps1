param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$launcher = Join-Path $resolvedRoot 'Satellite Observer.cmd'
$matlab = 'C:\Program Files\MATLAB\R2026b\bin\matlab.exe'

if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) {
    throw "Application launcher not found: $launcher"
}
if (-not (Test-Path -LiteralPath $matlab -PathType Leaf)) {
    throw "MATLAB R2026b not found: $matlab"
}

$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Satellite Observer.lnk'
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcher
$shortcut.WorkingDirectory = $resolvedRoot
$shortcut.IconLocation = "$matlab,0"
$shortcut.Description = 'Open Satellite Observer for live and engineering views'
$shortcut.Save()

$legacyShortcut = Join-Path $desktop 'Satellite Tracker.lnk'
if (Test-Path -LiteralPath $legacyShortcut -PathType Leaf) {
    $legacyTarget = $shell.CreateShortcut($legacyShortcut).TargetPath
    $legacyLauncher = Join-Path $resolvedRoot 'Satellite Tracker.cmd'
    if ($legacyTarget -eq $legacyLauncher) {
        Remove-Item -LiteralPath $legacyShortcut
    }
}

Write-Output $shortcutPath
