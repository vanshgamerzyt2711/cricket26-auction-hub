$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$base=Get-Content (Join-Path $PSScriptRoot 'BuildV501.ps1') -Raw
$rules=@(
  @('$version = ''5.0.1''','$version = ''5.0.3'''),
  @('$originalVersion = ''4.0.1''','$originalVersion = ''5.0.2'''),
  @('a9cac4cb748df508ef35fa1527a56e8d108de331339fef931d088d5067a7a202','55ef4e0b45d6bdc981e851cb3b3aaf7caab14e5ce117bf7fa47a394d60ba621f'),
  @('releases/download/v4.0.1/Cricket26AuctionHub-win-x64.zip','releases/download/v5.0.2/Cricket26AuctionHub-win-x64.zip'),
  @('tools/VersionPatch/VersionPatch.csproj','tools/UpdateRepair/UpdateRepair.csproj'),
  @("payloadFiles = @('Cricket26AuctionManager.exe', 'public-release.json')","payloadFiles = @('Cricket26AuctionManager.exe', 'public-release.json', 'AuctionUpdateHelper.exe')"),
  @("Copy-Item -LiteralPath $([char]36)publicPath -Destination (Join-Path $([char]36)delta 'public-release.json')","Copy-Item -LiteralPath $([char]36)publicPath -Destination (Join-Path $([char]36)delta 'public-release.json')`nCopy-Item -LiteralPath (Join-Path $([char]36)app 'AuctionUpdateHelper.exe') -Destination (Join-Path $([char]36)delta 'AuctionUpdateHelper.exe')"),
  @("Count = 3; Label = 'delta'","Count = 4; Label = 'delta'"),
  @("foreach ($([char]36)file in @('Cricket26AuctionManager.exe','public-release.json','release-manifest.json'))","foreach ($([char]36)file in @('Cricket26AuctionManager.exe','public-release.json','release-manifest.json','AuctionUpdateHelper.exe'))")
)
foreach($rule in $rules){
  if(!$base.Contains($rule[0])){throw "Missing expected source pipeline fragment: $($rule[0])"}
  $base=$base.Replace($rule[0],$rule[1])
}
$generated=Join-Path $PSScriptRoot '.generated-v503-build.ps1'
Set-Content -LiteralPath $generated -Value $base -Encoding utf8
try {
  & $generated
  if(!$?){throw 'Update repair build failed'}
}
finally { Remove-Item -LiteralPath $generated -ErrorAction SilentlyContinue }
