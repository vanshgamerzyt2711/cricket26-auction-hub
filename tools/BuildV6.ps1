$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Reuse the vetted, SHA-256 verified full and incremental update packager.
# The source V5.0.3 package already includes the working V5 update helper.
$builder = Get-Content (Join-Path $PSScriptRoot 'BuildV501.ps1') -Raw
$changes = @(
  @('$version = ''5.0.1''', '$version = ''6.0.0'''),
  @('$originalVersion = ''4.0.1''', '$originalVersion = ''5.0.3'''),
  @('a9cac4cb748df508ef35fa1527a56e8d108de331339fef931d088d5067a7a202', '820cc901b479911a6733f346c646fe038fb9330c29851d75e777a923db93c3be'),
  @('releases/download/v4.0.1/Cricket26AuctionHub-win-x64.zip', 'releases/download/v5.0.3/Cricket26AuctionHub-win-x64.zip'),
  @('tools/VersionPatch/VersionPatch.csproj', 'tools/VersionBumpV6/VersionBumpV6.csproj')
)
foreach ($change in $changes) {
  if (!$builder.Contains($change[0])) {
      throw "Unexpected known-good packager source: $($change[0])"
  }
  $builder = $builder.Replace($change[0], $change[1])
}
$generated = Join-Path $PSScriptRoot '.generated-v6-build.ps1'
Set-Content -LiteralPath $generated -Value $builder -Encoding utf8
try {
  & $generated
  if (!$?) { throw 'V6 packaging failed.' }
}
finally {
  Remove-Item -LiteralPath $generated -ErrorAction SilentlyContinue
}
