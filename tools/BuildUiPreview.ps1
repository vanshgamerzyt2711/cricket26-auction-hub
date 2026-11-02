$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest

# Reuse the tested integrity / ZIP / simulation / installer pipeline from V5.0.1.
# Only substitute the pinned base release and the reviewed UI patcher.
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$old = Get-Content (Join-Path $PSScriptRoot 'BuildV501.ps1') -Raw
$rules = @(
  @('$version = ''5.0.1''','$version = ''5.0.2'''),
  @('$originalVersion = ''4.0.1''','$originalVersion = ''5.0.1'''),
  @('a9cac4cb748df508ef35fa1527a56e8d108de331339fef931d088d5067a7a202','2acd17c4c0c39f617b7c6fc6cea8457641e96576cdbbd7a0cd7575e3e818dd84'),
  @('releases/download/v4.0.1/Cricket26AuctionHub-win-x64.zip','releases/download/v5.0.1/Cricket26AuctionHub-win-x64.zip'),
  @('tools/VersionPatch/VersionPatch.csproj','tools/UiPolish/UiPolish.csproj')
)
foreach($pair in $rules) {
    if(!$old.Contains($pair[0])){throw "Expected build script marker absent: $($pair[0])"}
    $old=$old.Replace($pair[0],$pair[1])
}
$generated = Join-Path $root '.generated-v502-build.ps1'
Set-Content -LiteralPath $generated -Value $old -Encoding utf8
try {
    & $generated
    if(!$?){throw 'UI preview build failed'}
}
finally {
    Remove-Item -LiteralPath $generated -ErrorAction SilentlyContinue
}
