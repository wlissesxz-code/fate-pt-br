param([string]$GamePath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'scripts\PatchEngine.ps1')
. (Join-Path $PSScriptRoot 'scripts\Discovery.ps1')
try{
 if(Get-Process -Name fate -ErrorAction SilentlyContinue){throw 'Feche o FATE antes de restaurar.'}
 $GamePath=Select-FateFolder $GamePath
 $stateRoot=Join-Path $GamePath '.fate-ptbr';$statePath=Join-Path $stateRoot 'state.json'
 if(-not(Test-Path -LiteralPath $statePath)){throw 'Nao ha backup deste instalador. Pacotes antigos precisam ser restaurados com o desinstalador correspondente.'}
 $state=Get-Content -LiteralPath $statePath -Raw -Encoding utf8 | ConvertFrom-Json
 if($state.status -in @('restored','rolled-back')){Write-Host 'A versao anterior ja foi restaurada.';exit 0}
 if($state.backup -notmatch '^backup-[0-9-]+$'){throw 'Caminho do backup invalido.'}
 $backupRoot=Resolve-GameFile $stateRoot $state.backup
 $allowed=@('LANG/en-US.dll','LANG/en-UK.dll')
 foreach($name in @('texts','scenes')){$plans=Get-Content -LiteralPath (Join-Path $PSScriptRoot "payload\$name.json") -Raw -Encoding utf8 | ConvertFrom-Json;$allowed+=@($plans | ForEach-Object path)}
 if(@($state.files).Count -lt 1 -or @($state.files).Count -gt $allowed.Count){throw 'Manifesto do backup invalido.'}
 $seen=@{}
 foreach($entry in $state.files){
  if($entry.path -notin $allowed -or $seen.ContainsKey([string]$entry.path)){throw 'Manifesto do backup contem caminhos invalidos ou repetidos.'}
  $seen[[string]$entry.path]=$true
  $saved=Resolve-GameFile $backupRoot $entry.path
  if(-not(Test-Path -LiteralPath $saved) -or (Get-FileHash -LiteralPath $saved).Hash -ne $entry.beforeHash){throw "Backup ausente ou danificado: $($entry.path)"}
  $target=Resolve-GameFile $GamePath $entry.path
  if(-not(Test-Path -LiteralPath $target)){throw 'O jogo foi atualizado ou teve arquivos removidos. Consulte o README antes de restaurar.'}
  $hash=(Get-FileHash -LiteralPath $target).Hash
  if($hash -ne $entry.afterHash -and $hash -ne $entry.beforeHash){throw "Arquivo alterado apos a instalacao: $($entry.path). Restauracao interrompida para nao sobrescrever outra versao do jogo."}
 }
 foreach($entry in $state.files){$target=Resolve-GameFile $GamePath $entry.path;Copy-Item -LiteralPath (Resolve-GameFile $backupRoot $entry.path) -Destination $target -Force;if((Get-FileHash -LiteralPath $target).Hash -ne $entry.beforeHash){throw "Restauracao nao conferiu: $($entry.path)"}}
 $state.status='restored';$state | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding utf8
 Write-Host 'Traducao removida. Arquivos anteriores restaurados e verificados.' -ForegroundColor Green
 Write-Host 'O backup foi mantido na pasta .fate-ptbr.'
}catch{Write-Host $_.Exception.Message -ForegroundColor Red;exit 1}
