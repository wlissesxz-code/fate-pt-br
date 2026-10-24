param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot
& (Join-Path $repo 'tests\Test-Payload.ps1')
$version=(Get-Content -LiteralPath (Join-Path $repo 'version.json') -Raw -Encoding utf8 | ConvertFrom-Json).version
if(-not $OutputDirectory){$OutputDirectory=Join-Path $repo 'dist'}
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$files=@('Instalar.cmd','Instalar.ps1','Desinstalar.cmd','Desinstalar.ps1','Validar.cmd','version.json','README.md','CHANGELOG.md','CONTRIBUTING.md','payload','scripts','tests','docs') | ForEach-Object {Join-Path $repo $_}
$zip=Join-Path $OutputDirectory "fate-pt-br-$version.zip"
Compress-Archive -LiteralPath $files -DestinationPath $zip -Force
$hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
Set-Content -LiteralPath ($zip+'.sha256') -Encoding ascii -Value "$hash  $([IO.Path]::GetFileName($zip))"
Write-Host $zip
