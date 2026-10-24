param([Parameter(Mandatory=$true)][string]$OriginalGamePath,[string]$WorkRoot=$env:TEMP)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot
$testRoot=Join-Path $WorkRoot ('fate-ptbr-integration-'+[Guid]::NewGuid().ToString('N'))
$plans=Get-Content -LiteralPath (Join-Path $repo 'payload\texts.json') -Raw -Encoding utf8 | ConvertFrom-Json
$scenes=Get-Content -LiteralPath (Join-Path $repo 'payload\scenes.json') -Raw -Encoding utf8 | ConvertFrom-Json
$paths=@($plans | ForEach-Object path)+@($scenes | ForEach-Object path)+@('LANG/en-US.dll','LANG/en-UK.dll')
function Get-CodeHashes([string]$Path){
 $b=[IO.File]::ReadAllBytes($Path);$pe=[BitConverter]::ToInt32($b,60);$count=[BitConverter]::ToUInt16($b,$pe+6);$start=$pe+24+[BitConverter]::ToUInt16($b,$pe+20);$result=@{}
 for($i=0;$i -lt $count;$i++){
  $p=$start+40*$i;$name=[Text.Encoding]::ASCII.GetString($b,$p,8).Trim([char]0);$size=[BitConverter]::ToInt32($b,$p+16);$offset=[BitConverter]::ToInt32($b,$p+20)
  if($name -ne '.rsrc' -and $size -gt 0){$section=New-Object byte[] $size;[Array]::Copy($b,$offset,$section,0,$size);$sha=[Security.Cryptography.SHA256]::Create();try{$result[$name]=[BitConverter]::ToString($sha.ComputeHash($section))}finally{$sha.Dispose()}}
 }
 return $result
}
function Run-Installer([string]$Game,[string]$Script,[string[]]$Extra=@()){
 & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo $Script) -GamePath $Game @Extra
 if($LASTEXITCODE -ne 0){throw "Falha: $Script"}
}
try{
 foreach($layout in @('all-locales','english-us-only')){
  $game=Join-Path $testRoot $layout;New-Item -ItemType Directory -Path $game -Force | Out-Null
  [IO.File]::WriteAllText((Join-Path $game 'fate.exe'),'TEST FIXTURE - NOT EXECUTABLE')
  $present=@($paths | Where-Object {$layout -ne 'english-us-only' -or $_ -notmatch '/en-UK(/|\.dll$)'})
  foreach($relative in $present){$destination=Join-Path $game $relative;New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null;Copy-Item -LiteralPath (Join-Path $OriginalGamePath $relative) -Destination $destination}
  if($layout -eq 'english-us-only'){
   # Simula uma variacao estrutural, sem alegar que os arquivos sao da Steam.
   $file=Join-Path $game 'ITEMS\en-US\items.dat';$enc=[Text.Encoding]::GetEncoding(1252);$text=[IO.File]::ReadAllText($file,$enc);[IO.File]::WriteAllText($file,"# cabecalho de outra distribuicao`r`n"+$text,$enc)
  }
  $codeBefore=Get-CodeHashes (Join-Path $game 'LANG\en-US.dll')
  $hashes=@{};foreach($relative in $present){$hashes[$relative]=(Get-FileHash -LiteralPath (Join-Path $game $relative)).Hash}
  Run-Installer $game 'Instalar.ps1' @('-ValidateOnly')
  foreach($relative in $present){if((Get-FileHash -LiteralPath (Join-Path $game $relative)).Hash -ne $hashes[$relative]){throw 'Validar alterou o jogo'}}
  Run-Installer $game 'Instalar.ps1'
  $codeAfter=Get-CodeHashes (Join-Path $game 'LANG\en-US.dll')
  foreach($section in $codeBefore.Keys){if($codeBefore[$section] -cne $codeAfter[$section]){throw 'Codigo da DLL alterado fora dos recursos'}}
  $state=Get-Content -LiteralPath (Join-Path $game '.fate-ptbr\state.json') -Raw -Encoding utf8 | ConvertFrom-Json
  if($state.status -ne 'installed' -or $state.files.Count -ne $present.Count){throw 'Estado de instalacao invalido'}
  Run-Installer $game 'Instalar.ps1' # idempotencia
  # Recuse sobrescrever um arquivo que mudou depois da instalacao.
  $protected=Join-Path $game 'SPELLS\spells.dat';$installed=[IO.File]::ReadAllBytes($protected);[IO.File]::AppendAllText($protected,"`r`n# modificacao externa")
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'Desinstalar.ps1') -GamePath $game
  if($LASTEXITCODE -eq 0){throw 'Desinstalador aceitou arquivo alterado'}
  [IO.File]::WriteAllBytes($protected,$installed)
  Run-Installer $game 'Desinstalar.ps1'
  foreach($relative in $present){if((Get-FileHash -LiteralPath (Join-Path $game $relative)).Hash -ne $hashes[$relative]){throw "Restauracao diferente: $relative"}}
  # Incompatibilidade deve ser rejeitada antes de criar backup ou escrever arquivos.
  [IO.File]::WriteAllText((Join-Path $game 'ITEMS\items.dat'),'ARQUIVO INCOMPATIVEL')
  $before=(Get-FileHash -LiteralPath (Join-Path $game 'LANG\en-US.dll')).Hash
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'Instalar.ps1') -GamePath $game
  if($LASTEXITCODE -eq 0 -or (Get-FileHash -LiteralPath (Join-Path $game 'LANG\en-US.dll')).Hash -ne $before){throw 'Incompatibilidade nao foi recusada com seguranca'}
  Write-Host "PASSOU: $layout; validacao, instalacao, idempotencia, recusa de modificacao, restauracao e recusa de versao." -ForegroundColor Green
 }
}finally{
 $base=[IO.Path]::GetFullPath($WorkRoot).TrimEnd('\')+'\';$safe=[IO.Path]::GetFullPath($testRoot)
 if($safe.StartsWith($base,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $safe -Leaf) -match '^fate-ptbr-integration-[a-f0-9]{32}$' -and (Test-Path -LiteralPath $safe)){Remove-Item -LiteralPath $safe -Recurse -Force}
}


