$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot
. (Join-Path $root 'scripts\PatchEngine.ps1')
$ids=@{}
$entries=Get-Content -LiteralPath (Join-Path $root 'payload\interface.json') -Raw -Encoding utf8 | ConvertFrom-Json
foreach($e in $entries){
 if($ids.ContainsKey([int]$e.id)){throw 'ID repetido'};$ids[[int]$e.id]=$true
 foreach($original in $e.sources){
  if($e.id -eq 824){$original=$original.Replace('#2','$2')} # typo conhecido da DLL en-UK original
  $a=([regex]::Matches($original,'\$\d+') | ForEach-Object Value | Sort-Object) -join '|'
  $b=([regex]::Matches($e.text,'\$\d+') | ForEach-Object Value | Sort-Object) -join '|'
  if($a -cne $b){throw "Variaveis alteradas: $($e.id)"}
 }
}
$plans=Get-Content -LiteralPath (Join-Path $root 'payload\texts.json') -Raw -Encoding utf8 | ConvertFrom-Json
foreach($p in $plans){
 [void](Resolve-GameFile $root $p.path)
 $last=-1
 foreach($op in $p.operations){if($op.index -le $last){throw 'Operacoes fora de ordem'};$last=$op.index;if($op.before -ceq $op.after){throw 'Operacao sem alteracao'}}
}
# O fallback por contexto deve tolerar um cabecalho inserido, mas recusar dados distintos.
$temp=Join-Path ([IO.Path]::GetTempPath()) ('fate-ptbr-unit-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try{
 $source=Join-Path $temp 'source.dat';$target=Join-Path $temp 'target.dat';$enc=[Text.Encoding]::GetEncoding(1252)
 $plan=[pscustomobject]@{path='sample.dat';sourceHash=(Get-NormalizedHash @('[ITEM]','<NAME>:Axe','<VALUE>:5','[/ITEM]'));operations=@([pscustomobject]@{index=1;before='<NAME>:Axe';after='<NAME>:Machado';left=@('[ITEM]');right=@('<VALUE>:5','[/ITEM]')})}
 [IO.File]::WriteAllLines($source,@('# extra','[ITEM]','<NAME>:Axe','<VALUE>:5','[/ITEM]'),$enc)
 $result=Apply-TextPlan $source $target $plan
 if($result.mode -ne 'contexto' -or [IO.File]::ReadAllText($target,$enc) -notmatch '<NAME>:Machado'){throw 'Fallback por contexto falhou'}
 [IO.File]::WriteAllLines($source,@('[ITEM]','<NAME>:Axe','<VALUE>:99','[/ITEM]'),$enc)
 $rejected=$false;try{[void](Apply-TextPlan $source $target $plan)}catch{$rejected=$true}
 if(-not $rejected){throw 'Arquivo incompatível foi aceito'}
 foreach($path in @('..\fate.exe','C:\outside.dat')){$rejected=$false;try{[void](Resolve-GameFile $temp $path)}catch{$rejected=$true};if(-not $rejected){throw 'Caminho externo aceito'}}
 . (Join-Path $root 'scripts\Discovery.ps1')
 $steam=Join-Path $temp 'Steam';$library=Join-Path $temp 'Outra biblioteca';$fakeGame=Join-Path $library 'steamapps\common\FATE'
 New-Item -ItemType Directory -Path (Join-Path $steam 'steamapps'),(Join-Path $library 'steamapps') -Force | Out-Null
 foreach($relative in @('fate.exe','LANG\en-US.dll','ITEMS\items.dat','SPELLS\spells.dat','MONSTERS\monsters.dat')){$f=Join-Path $fakeGame $relative;New-Item -ItemType Directory -Path (Split-Path $f) -Force | Out-Null;[IO.File]::WriteAllText($f,'TEST FIXTURE')}
 [IO.File]::WriteAllText((Join-Path $steam 'steamapps\libraryfolders.vdf'),('"libraryfolders" { "0" { "path" "'+$library.Replace('\','\\')+'" } }'))
 [IO.File]::WriteAllText((Join-Path $library 'steamapps\appmanifest_246840.acf'),'"AppState" { "appid" "246840" "installdir" "FATE" }')
 $found=@(Find-FateInstallPaths -AdditionalSteamRoots @($steam))
 if([IO.Path]::GetFullPath($fakeGame) -notin $found){throw 'Deteccao de biblioteca adicional da Steam falhou'}
}finally{
 $safe=[IO.Path]::GetFullPath($temp);$base=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
 if($safe.StartsWith($base,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $safe -Leaf) -match '^fate-ptbr-unit-[a-f0-9]{32}$'){Remove-Item -LiteralPath $safe -Recurse -Force}
}
$binary=@(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {$_.Extension -in @('.dll','.exe','.scn','.ogg','.wav','.ffd')})
if($binary.Count){throw 'Arquivo original ou audio foi incluido no pacote'}
Write-Host "Validacao estatica concluida: $($entries.Count) recursos, $($plans.Count) planos e testes do aplicador." -ForegroundColor Green


