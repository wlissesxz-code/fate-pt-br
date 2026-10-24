param([string]$GamePath,[switch]$ValidateOnly)
$ErrorActionPreference='Stop'
Set-StrictMode -Version 2
. (Join-Path $PSScriptRoot 'scripts\PatchEngine.ps1')
. (Join-Path $PSScriptRoot 'scripts\Discovery.ps1')
$stage=$null
try{
 if(Get-Process -Name fate -ErrorAction SilentlyContinue){throw 'Feche o FATE antes de continuar.'}
 $GamePath=Select-FateFolder $GamePath
 $version=(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'version.json') -Raw -Encoding utf8 | ConvertFrom-Json).version
 $stateRoot=Join-Path $GamePath '.fate-ptbr';$statePath=Join-Path $stateRoot 'state.json'
 if(Test-Path -LiteralPath $statePath){
  $state=Get-Content -LiteralPath $statePath -Raw -Encoding utf8 | ConvertFrom-Json
  if($state.status -eq 'installed'){
   $valid=$true;foreach($entry in $state.files){$target=Resolve-GameFile $GamePath $entry.path;if(-not(Test-Path -LiteralPath $target) -or (Get-FileHash -LiteralPath $target).Hash -ne $entry.afterHash){$valid=$false;break}}
   if($valid -and $state.version -eq $version){Write-Host 'Esta versao da traducao ja esta instalada e integra.' -ForegroundColor Green;exit 0}
   throw 'Ha uma traducao instalada ou modificada. Use Desinstalar.cmd antes de instalar outra versao. Se a loja atualizou o jogo, consulte o README.'
  }
  if($state.status -eq 'installing'){throw 'Instalacao anterior interrompida. Use Desinstalar.cmd para restaurar o backup antes de continuar.'}
 }
 $stage=Join-Path $PSScriptRoot ('.stage-'+[Guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $stage | Out-Null
 $prepared=[Collections.Generic.List[object]]::new();$validation=[Collections.Generic.List[object]]::new()
 $plans=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'payload\texts.json') -Raw -Encoding utf8 | ConvertFrom-Json
 foreach($plan in $plans){
  $source=Resolve-GameFile $GamePath $plan.path
  if(-not(Test-Path -LiteralPath $source)){if($plan.optional){continue};throw "Arquivo necessario ausente: $($plan.path)"}
  $destination=Resolve-GameFile $stage $plan.path;New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
  $validation.Add((Apply-TextPlan $source $destination $plan))
  $prepared.Add([pscustomobject]@{path=$plan.path;source=$source;staged=$destination;beforeHash=(Get-FileHash -LiteralPath $source).Hash;afterHash=(Get-FileHash -LiteralPath $destination).Hash})
 }
 $scenes=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'payload\scenes.json') -Raw -Encoding utf8 | ConvertFrom-Json
 foreach($plan in $scenes){
  $source=Resolve-GameFile $GamePath $plan.path
  if(-not(Test-Path -LiteralPath $source)){if($plan.optional){continue};throw "Cena necessaria ausente: $($plan.path)"}
  $destination=Resolve-GameFile $stage $plan.path;New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
  Apply-ScenePlan $source $destination $plan
  $prepared.Add([pscustomobject]@{path=$plan.path;source=$source;staged=$destination;beforeHash=(Get-FileHash -LiteralPath $source).Hash;afterHash=(Get-FileHash -LiteralPath $destination).Hash})
 }
 . (Join-Path $PSScriptRoot 'scripts\Resources.ps1')
 $resources=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'payload\interface.json') -Raw -Encoding utf8 | ConvertFrom-Json
 foreach($locale in @('en-US','en-UK')){
  $relative="LANG/$locale.dll";$source=Resolve-GameFile $GamePath $relative
  if(-not(Test-Path -LiteralPath $source)){if($locale -eq 'en-UK'){continue};throw 'Biblioteca en-US.dll ausente.'}
  $destination=Resolve-GameFile $stage $relative;New-Item -ItemType Directory -Path (Split-Path $destination) -Force | Out-Null
  Build-FateDll $source $destination $resources
  $prepared.Add([pscustomobject]@{path=$relative;source=$source;staged=$destination;beforeHash=(Get-FileHash -LiteralPath $source).Hash;afterHash=(Get-FileHash -LiteralPath $destination).Hash})
 }
 if($ValidateOnly){Write-Host "Validacao concluida: $($prepared.Count) arquivos compativeis. Nenhum arquivo do jogo foi alterado." -ForegroundColor Green;exit 0}
 # Revalide para detectar alteracoes externas enquanto os arquivos eram preparados.
 foreach($entry in $prepared){if((Get-FileHash -LiteralPath $entry.source).Hash -ne $entry.beforeHash){throw 'O jogo ou outro programa modificou os arquivos durante a preparacao. Tente novamente com o jogo fechado.'}}
 $backupName='backup-'+(Get-Date -Format 'yyyyMMdd-HHmmss-fff');$backupRoot=Join-Path $stateRoot $backupName
 foreach($entry in $prepared){$saved=Resolve-GameFile $backupRoot $entry.path;New-Item -ItemType Directory -Path (Split-Path $saved) -Force | Out-Null;Copy-Item -LiteralPath $entry.source -Destination $saved;if((Get-FileHash -LiteralPath $saved).Hash -ne $entry.beforeHash){throw 'Backup nao conferiu. Nenhuma traducao foi aplicada.'}}
 $journal=[pscustomobject]@{version=$version;status='installing';backup=$backupName;files=@($prepared | Select-Object path,beforeHash,afterHash)}
 $journal | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding utf8
 try{
  foreach($entry in $prepared){Copy-Item -LiteralPath $entry.staged -Destination $entry.source -Force;if((Get-FileHash -LiteralPath $entry.source).Hash -ne $entry.afterHash){throw "Copia nao conferiu: $($entry.path)"}}
  $journal.status='installed';$journal | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding utf8
 }catch{
  $problem=$_.Exception.Message
  foreach($entry in $prepared){Copy-Item -LiteralPath (Resolve-GameFile $backupRoot $entry.path) -Destination $entry.source -Force}
  foreach($entry in $prepared){if((Get-FileHash -LiteralPath $entry.source).Hash -ne $entry.beforeHash){throw "Restauracao automatica incompleta. Backup preservado em $backupRoot"}}
  $journal.status='rolled-back';$journal | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $statePath -Encoding utf8
  throw "Instalacao desfeita: $problem"
 }
 Write-Host "Traducao $version instalada!" -ForegroundColor Green
 Write-Host 'Mantenha o idioma do jogo em ingles e abra o FATE normalmente.'
 Write-Host "Backup: $backupRoot"
}catch{Write-Host $_.Exception.Message -ForegroundColor Red;exit 1}
finally{
 if($stage -and (Test-Path -LiteralPath $stage)){
  $safeRoot=[IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')+'\';$safeTarget=[IO.Path]::GetFullPath($stage)
  if($safeTarget.StartsWith($safeRoot,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $safeTarget -Leaf) -match '^\.stage-[a-f0-9]{32}$'){Remove-Item -LiteralPath $safeTarget -Recurse -Force}
 }
}

