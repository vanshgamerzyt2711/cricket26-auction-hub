$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = 'vanshgamerzyt2711/cricket26-auction-hub'
$version = '5.0.1'
$originalVersion = '4.0.1'
$expectedOriginal = 'a9cac4cb748df508ef35fa1527a56e8d108de331339fef931d088d5067a7a202'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$archive = Join-Path $env:RUNNER_TEMP 'auction-v401.zip'
$app = Join-Path $root 'AppPayload'
$out = Join-Path $root 'Output'
$delta = Join-Path $env:RUNNER_TEMP 'auction-delta'
$originalZipUrl = "https://github.com/$repo/releases/download/v4.0.1/Cricket26AuctionHub-win-x64.zip"

New-Item -Path $app, $out, $delta -ItemType Directory -Force | Out-Null

Write-Host "Fetching and verifying the known V4.0.1 payload."
Invoke-WebRequest -Uri $originalZipUrl -OutFile $archive
$actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($actual -ne $expectedOriginal) { throw "V4.0.1 SHA-256 mismatch: $actual" }
Expand-Archive -LiteralPath $archive -DestinationPath $app -Force

$main = Join-Path $app 'Cricket26AuctionManager.exe'
$publicPath = Join-Path $app 'public-release.json'
$fullManifestPath = Join-Path $app 'release-manifest.json'
if (!(Test-Path $main) -or !(Test-Path $publicPath) -or !(Test-Path $fullManifestPath)) {
    throw 'Incomplete original application package.'
}

$originalManifest = Get-Content $fullManifestPath -Raw | ConvertFrom-Json -Depth 80
$public = Get-Content $publicPath -Raw | ConvertFrom-Json -Depth 80
if ($originalManifest.appId -ne 'Cricket26AuctionHub' -or
    $originalManifest.version -ne $originalVersion -or
    $public.version -ne $originalVersion -or
    $null -eq $originalManifest.files) {
    throw 'Unexpected base package metadata.'
}

# Reject unexpected extra files from the original ZIP.
$included = @{}
foreach ($item in $originalManifest.files) {
    if ($item.path -eq 'release-manifest.json' -or [string]::IsNullOrWhiteSpace($item.path)) {
        throw 'Invalid manifest path.'
    }
    $key = $item.path.Replace('\','/')
    if ($included.ContainsKey($key.ToLowerInvariant())) { throw "Duplicate manifest entry: $key" }
    $included[$key.ToLowerInvariant()] = $true
    $file = Join-Path $app ($key.Replace('/',[IO.Path]::DirectorySeparatorChar))
    if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing payload file: $key" }
    $digest = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($digest -ne $item.sha256) { throw "Original payload file failed SHA-256: $key" }
}
$zipFiles = @(Get-ChildItem $app -Recurse -File)
if ($zipFiles.Count -ne ($included.Count + 1)) {
    throw "Unexpected original ZIP file count: actual $($zipFiles.Count), expected $($included.Count + 1)"
}
Write-Host "Original payload integrity verified: $($included.Count) files."

Write-Host "Updating only app version markers, not changing game functionality."
$patchProject = Join-Path $root 'tools/VersionPatch/VersionPatch.csproj'
dotnet run --project $patchProject -c Release -- $main $version
if ($LASTEXITCODE -ne 0) { throw 'Assembly patching failed.' }
$metadata = (Get-Item $main).VersionInfo
Write-Host "Legacy Windows VERSIONINFO resource: $($metadata.FileVersion) (not used for GitHub update comparison)."
Write-Host "New managed assembly version and embedded release strings were verified by the patching tool."

$public.version = $version
$public | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $publicPath -Encoding utf8

$full = $originalManifest
$full.version = $version
foreach ($item in $full.files) {
    $itemPath = Join-Path $app ($item.path.Replace('/',[IO.Path]::DirectorySeparatorChar))
    $item.sha256 = (Get-FileHash -LiteralPath $itemPath -Algorithm SHA256).Hash.ToLowerInvariant()
}
$full | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $fullManifestPath -Encoding utf8

# Delta spec lists the whole target install for validation, but carries only changed files.
$deltaSpec = [ordered]@{
    appId = 'Cricket26AuctionHub'
    version = $version
    files = @($full.files)
    packageKind = 'delta'
    payloadFiles = @('Cricket26AuctionManager.exe', 'public-release.json')
}
$deltaSpecFile = Join-Path $out 'Cricket26AuctionHub-update-manifest.json'
$deltaSpec | ConvertTo-Json -Depth 80 | Set-Content -LiteralPath $deltaSpecFile -Encoding utf8
Copy-Item -LiteralPath $main -Destination (Join-Path $delta 'Cricket26AuctionManager.exe')
Copy-Item -LiteralPath $publicPath -Destination (Join-Path $delta 'public-release.json')
Copy-Item -LiteralPath $deltaSpecFile -Destination (Join-Path $delta 'release-manifest.json')

$deltaZip = Join-Path $out 'Cricket26AuctionHub-update-win-x64.zip'
$fullZip = Join-Path $out 'Cricket26AuctionHub-win-x64.zip'
# Create ZIPs without folder-marker entries. The legacy release parser rejects unlisted entries.
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.ZipFile
function New-CleanZip([string] $source, [string] $destination) {
    if(Test-Path $destination) { Remove-Item -LiteralPath $destination -Force }
    $z = [IO.Compression.ZipFile]::Open($destination, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach($file in (Get-ChildItem $source -File -Recurse | Sort-Object FullName)) {
            $relative = $file.FullName.Substring($source.Length + 1).Replace('\','/')
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $z, $file.FullName, $relative, [IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally { $z.Dispose() }
}
New-CleanZip $delta $deltaZip
New-CleanZip $app $fullZip

# Read ZIPs back and check all expected entries are present. Reject duplicate entries.
foreach ($check in @(
    @{ File = $fullZip; Count = $included.Count + 1; Label = 'full' },
    @{ File = $deltaZip; Count = 3; Label = 'delta' }
)) {
    $z = [IO.Compression.ZipFile]::OpenRead($check.File)
    try {
        if ($z.Entries.Count -ne $check.Count) {
            throw "$($check.Label) ZIP file count mismatch: $($z.Entries.Count) != $($check.Count)"
        }
        $seen = @{}
        foreach ($entry in $z.Entries) {
            $normalized = $entry.FullName.Replace('\','/').ToLowerInvariant()
            if ($seen.ContainsKey($normalized)) { throw "Duplicate ZIP path: $normalized" }
            $seen[$normalized] = $true
        }
        foreach ($required in @('release-manifest.json', 'Cricket26AuctionManager.exe', 'public-release.json')) {
            if (!$seen.ContainsKey($required.ToLowerInvariant())) {throw "Missing ZIP member: $required"}
        }
    }
    finally { $z.Dispose() }
}

# Reconstruct the patched install from the V4.0.1 original and the delta ZIP.
$simulated = Join-Path $env:RUNNER_TEMP 'upgrade-smoke-test'
New-Item -Path $simulated -ItemType Directory -Force | Out-Null
Expand-Archive -LiteralPath $archive -DestinationPath $simulated
Expand-Archive -LiteralPath $deltaZip -DestinationPath (Join-Path $env:RUNNER_TEMP 'upgrade-delta-expanded')
$unpacked = Join-Path $env:RUNNER_TEMP 'upgrade-delta-expanded'
foreach ($file in @('Cricket26AuctionManager.exe','public-release.json','release-manifest.json')) {
    Copy-Item -LiteralPath (Join-Path $unpacked $file) -Destination (Join-Path $simulated $file) -Force
}
foreach ($item in $full.files) {
    $file = Join-Path $simulated ($item.path.Replace('/',[IO.Path]::DirectorySeparatorChar))
    if(!(Test-Path $file)){throw "Simulated update missing $($item.path)"}
    $hash=(Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant()
    if($hash -ne $item.sha256){throw "Simulated upgrade hash mismatch: $($item.path)"}
}
$simVersion = (Get-Content (Join-Path $simulated 'public-release.json') -Raw | ConvertFrom-Json).version
if($simVersion -ne $version){throw "Simulated version mismatch: $simVersion"}
Write-Host 'PASS: V4.0.1 -> V5.0.1 delta reconstruction; all target file hashes verified.'

# Build an offline installer using exactly the same updated app payload.
$baseIss = Get-Content (Join-Path $root 'AuctionHub-v5.iss') -Raw
if (!$baseIss.Contains('AppVersion=5.0.0') -or !$baseIss.Contains('{autodesktop}')) {
    throw 'Unexpected installer script or desktop shortcut absent.'
}
$iss = Join-Path $root 'AuctionHub-v501.iss'
$baseIss.Replace('AppVersion=5.0.0', "AppVersion=$version") | Set-Content $iss -Encoding utf8
$compiler = @(
    'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
    'C:\Program Files\Inno Setup 6\ISCC.exe',
    'C:\Program Files (x86)\Inno Setup 7\ISCC.exe',
    'C:\Program Files\Inno Setup 7\ISCC.exe'
) | Where-Object {Test-Path $_} | Select-Object -First 1
if(!$compiler){throw 'Inno Setup compiler not found.'}
& $compiler $iss
if($LASTEXITCODE -ne 0){throw 'Inno Setup compile failed.'}
$setup = Join-Path $out 'Cricket26AuctionHub-Setup.exe'
if(!(Test-Path $setup)){throw 'Offline installer not generated.'}

$checksumPath = Join-Path $out 'SHA256SUMS.txt'
Get-ChildItem $out -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object Name |
    ForEach-Object {
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$hash  $($_.Name)"
    } | Set-Content -LiteralPath $checksumPath -Encoding ascii

Write-Host 'VALIDATION PASSED. RELEASE ASSETS:'
Get-ChildItem $out -File | ForEach-Object { Write-Host "$($_.Name) : $($_.Length) bytes" }
