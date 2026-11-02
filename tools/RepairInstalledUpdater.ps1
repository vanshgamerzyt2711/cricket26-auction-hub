param(
    [switch]$DetectOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = 'vanshgamerzyt2711/cricket26-auction-hub'
$version = 'v5.0.3'
$expectedZipSha256 = '5e16f185e44ad2b3d82b176d0f2df824befd824abafc66e0bff4672c62e30b83'
$url = 'https://github.com/' + $repo + '/releases/download/' + $version + '/Cricket26AuctionHub-update-win-x64.zip'
$legacy = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Cricket26AuctionHub\App')).TrimEnd('\')
$innoDefault = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA 'Programs\Cricket26AuctionHub')).TrimEnd('\')

function Normalize-Folder([string]$value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return $null }
    try {
        $expanded = [Environment]::ExpandEnvironmentVariables($value.Trim('" '))
        return [IO.Path]::GetFullPath($expanded).TrimEnd('\')
    }
    catch { return $null }
}

$found = @{}
function Add-Install([string]$folder, [string]$source) {
    $n = Normalize-Folder $folder
    if (!$n) { return }
    $exe = Join-Path $n 'Cricket26AuctionManager.exe'
    if (!(Test-Path -LiteralPath $exe -PathType Leaf)) { return }
    $k = $n.ToLowerInvariant()
    if (!$found.ContainsKey($k)) {
        $found[$k] = [pscustomobject]@{ Folder = $n; Source = $source }
    } else {
        $found[$k].Source += ', ' + $source
    }
}

Write-Host ''
Write-Host 'Cricket 26 Auction Hub - Inno Setup updater repair' -ForegroundColor Cyan
Write-Host 'Detecting the actual installed app location...' -ForegroundColor Cyan
Add-Install $legacy 'legacy default path'
Add-Install $innoDefault 'Inno Setup default path'

$uninstallKeys = @(
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Cricket26AuctionHub.Standard_is1',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Cricket26AuctionHub.Standard_is1',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Cricket26AuctionHub.Standard_is1'
)
foreach ($key in $uninstallKeys) {
    if (Test-Path -LiteralPath $key) {
        try {
            $p = Get-ItemProperty -LiteralPath $key
            if ($p.InstallLocation) {
                Write-Host ('Inno Setup registry: ' + $p.InstallLocation)
                Add-Install $p.InstallLocation 'Inno Setup registration'
            }
        } catch { Write-Warning ('Could not read registry: ' + $key) }
    }
}

try {
    $shell = New-Object -ComObject WScript.Shell
    $shortcutPaths = @(
        (Join-Path ([Environment]::GetFolderPath('Desktop')) 'Cricket 26 Auction Hub.lnk'),
        (Join-Path ([Environment]::GetFolderPath('CommonDesktopDirectory')) 'Cricket 26 Auction Hub.lnk'),
        (Join-Path ([Environment]::GetFolderPath('Programs')) 'Cricket 26 Auction Hub.lnk'),
        (Join-Path ([Environment]::GetFolderPath('Programs')) 'Cricket 26 Auction Hub\Cricket 26 Auction Hub.lnk')
    )
    foreach ($lnk in $shortcutPaths) {
        if (Test-Path -LiteralPath $lnk) {
            $target = $shell.CreateShortcut($lnk).TargetPath
            if ($target) {
                Write-Host ('Shortcut: ' + $target)
                Add-Install (Split-Path -Path $target -Parent) 'Windows shortcut'
            }
        }
    }
} catch { Write-Warning 'Shortcuts could not be inspected; registry and default paths were checked.' }

try {
    $running = @(Get-CimInstance Win32_Process -Filter "Name='Cricket26AuctionManager.exe'" -ErrorAction SilentlyContinue)
    foreach ($proc in $running) {
        if ($proc.ExecutablePath) {
            Write-Host ('Running app: ' + $proc.ExecutablePath)
            Add-Install (Split-Path -Path $proc.ExecutablePath -Parent) 'running process'
        }
    }
} catch { Write-Warning 'Running app process could not be inspected.' }

$installs = @($found.Values | Sort-Object Folder)
if ($installs.Count -eq 0) {
    Write-Host 'No known Auction Hub installation found.' -ForegroundColor Red
    Write-Host 'Start the Auction Hub, then rerun this script with -DetectOnly to identify the real exe path.'
    exit 2
}

Write-Host ''
for ($i=0; $i -lt $installs.Count; $i++) {
    $item = $installs[$i]
    $type = if ($item.Folder -ieq $legacy) { 'LEGACY' } elseif ($item.Folder -ieq $innoDefault) { 'INNO DEFAULT' } else { 'CUSTOM / OTHER' }
    Write-Host ('[' + ($i+1) + '] ' + $item.Folder + '   (' + $type + ')')
    Write-Host ('    Found via: ' + $item.Source)
}

if ($DetectOnly) {
    Write-Host ''
    Write-Host 'Detection-only mode: nothing was modified.'
    exit 0
}

$selection = 0
if ($installs.Count -eq 1) {
    $selection = 1
} else {
    $answer = Read-Host 'Which app installation do you launch? Enter its number (or press Enter to cancel)'
    if (![int]::TryParse($answer, [ref]$selection) -or $selection -lt 1 -or $selection -gt $installs.Count) {
        Write-Host 'Cancelled. No files changed.'
        exit 1
    }
}

$root = $installs[$selection-1].Folder
$allowed = ($root -ieq $legacy -or $root -ieq $innoDefault)
if (!$allowed) {
    Write-Host ''
    Write-Host ('Actual app installation: ' + $root) -ForegroundColor Yellow
    Write-Host 'This is a custom folder not supported by the existing Update & Restart security check.' -ForegroundColor Yellow
    Write-Host 'Replacing the helper would NOT fix it, so no files were changed.'
    Write-Host ('Install the current official Inno Setup release into its default folder: ' + $innoDefault)
    Write-Host 'Then launch the shortcut pointing to the new default folder.'
    exit 3
}

$current = $root
while (![string]::IsNullOrWhiteSpace($current)) {
    if ((Test-Path -LiteralPath $current -PathType Container) -and
        ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'Linked or junction installation paths are unsafe. No files modified.'
    }
    $parent = Split-Path -Path $current -Parent
    if (!$parent -or $parent -eq $current) { break }
    $current = $parent
}

$exe = Join-Path $root 'Cricket26AuctionManager.exe'
$helper = Join-Path $root 'AuctionUpdateHelper.exe'
$manifest = Join-Path $root 'release-manifest.json'
if (!(Test-Path -LiteralPath $exe) -or !(Test-Path -LiteralPath $helper) -or !(Test-Path -LiteralPath $manifest)) {
    throw 'Application exe, helper, or signed-downloaded release manifest missing. Repair via the full official Setup instead.'
}
$metadata = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
if ($metadata.appId -ne 'Cricket26AuctionHub') {
    throw 'Installed application identity does not match. Refusing to write.'
}

if (@(Get-Process -Name 'Cricket26AuctionManager','AuctionUpdateHelper' -ErrorAction SilentlyContinue).Count -gt 0) {
    Write-Host 'Close Auction Hub AND the Setup/Update error window, then rerun this script.' -ForegroundColor Yellow
    exit 4
}

Write-Host ''
Write-Host ('Repairing updater in ' + $root) -ForegroundColor Cyan
Write-Host 'UserData and your auction profiles will not be touched.'

$tempDir = Join-Path $env:TEMP ('AuctionHub-verified-repair-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
try {
    $zipPath = Join-Path $tempDir 'official-update.zip'
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $zipPath
    $sha = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sha -ne $expectedZipSha256) { throw 'GitHub update package checksum mismatch. No files changed.' }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $entry = $zip.GetEntry('AuctionUpdateHelper.exe')
        if (!$entry -or $entry.Length -lt 10000) { throw 'Verified update archive has no valid updater helper.' }
        $newHelper = Join-Path $tempDir 'AuctionUpdateHelper.exe'
        $inputStream = $entry.Open()
        $outputStream = [IO.File]::Open($newHelper, [IO.FileMode]::Create, [IO.FileAccess]::Write)
        try { $inputStream.CopyTo($outputStream) }
        finally { $outputStream.Dispose(); $inputStream.Dispose() }
    }
    finally { $zip.Dispose() }

    $backups = Join-Path $env:LOCALAPPDATA 'Cricket26AuctionHub\UpdaterBackups'
    New-Item -ItemType Directory -Force -Path $backups | Out-Null
    $backup = Join-Path $backups ('AuctionUpdateHelper-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.exe')
    Copy-Item -LiteralPath $helper -Destination $backup
    $expectedHelper = (Get-FileHash -LiteralPath $newHelper -Algorithm SHA256).Hash
    try {
        Copy-Item -LiteralPath $newHelper -Destination $helper -Force
        $actualHelper = (Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash
        if ($expectedHelper -ne $actualHelper) { throw 'Post-copy helper checksum mismatch.' }
    }
    catch {
        Copy-Item -LiteralPath $backup -Destination $helper -Force
        throw
    }

    Write-Host ''
    Write-Host 'SUCCESS: Verified V5.0.3 updater helper installed in the actual app folder.' -ForegroundColor Green
    Write-Host ('Original helper backup: ' + $backup)
    Write-Host 'Open the SAME app shortcut and use Updates > Update & Restart.'
}
finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
