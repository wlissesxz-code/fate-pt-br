Set-StrictMode -Version 2
function Get-Sha256Text([string]$Text){
 $sha=[Security.Cryptography.SHA256]::Create()
 try{return ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($Text)))).Replace('-','')}finally{$sha.Dispose()}
}
function Get-NormalizedHash([string[]]$Lines){
 $end=$Lines.Length
 while($end -gt 0 -and -not $Lines[$end-1].Trim()){$end--}
 if($end -eq 0){return Get-Sha256Text ''}
 return Get-Sha256Text (($Lines[0..($end-1)]) -join "`n")
}
function Test-Anchor([string[]]$Lines,[int]$Index,$Operation){
 if($Index -lt 0 -or $Index -ge $Lines.Length -or $Lines[$Index] -cne $Operation.before){return $false}
 $left=@($Operation.left);$right=@($Operation.right)
 if($Index -lt $left.Count -or $Index+$right.Count -ge $Lines.Length){return $false}
 for($i=0;$i -lt $left.Count;$i++){if($Lines[$Index-$left.Count+$i] -cne $left[$i]){return $false}}
 for($i=0;$i -lt $right.Count;$i++){if($Lines[$Index+1+$i] -cne $right[$i]){return $false}}
 return $true
}
function Apply-TextPlan([string]$Source,[string]$Destination,$Plan){
 $enc=[Text.Encoding]::GetEncoding(1252)
 $lines=[IO.File]::ReadAllLines($Source,$enc)
 $output=[string[]]$lines.Clone()
 $exact=(Get-NormalizedHash $lines) -eq $Plan.sourceHash
 $byLine=@{}
 if(-not $exact){for($i=0;$i -lt $lines.Length;$i++){$key=$lines[$i];if(-not $byLine.ContainsKey($key)){$byLine[$key]=[Collections.Generic.List[int]]::new()};$byLine[$key].Add($i)}}
 $last=-1;$offset=0
 foreach($op in @($Plan.operations)){
  $selected=-1
  if($exact){$selected=[int]$op.index;if($lines[$selected] -cne $op.before){throw "Plano inconsistente: $($Plan.path)"}}
  else{
   $candidate=[int]$op.index+$offset
   if($candidate -gt $last -and (Test-Anchor $lines $candidate $op)){$selected=$candidate}
   elseif($byLine.ContainsKey([string]$op.before)){
    $found=@($byLine[[string]$op.before] | Where-Object {$_ -gt $last -and (Test-Anchor $lines $_ $op)})
    if($found.Count -eq 1){$selected=$found[0]}
   }
   if($selected -lt 0){throw "Arquivo modificado ou de versao nao reconhecida: $($Plan.path), texto $($op.index). Use os arquivos originais em ingles. Nenhuma alteracao foi aplicada ao jogo."}
   $offset=$selected-[int]$op.index
  }
  if($selected -le $last){throw 'Operacoes sobrepostas no plano de traducao.'}
  $last=$selected;$output[$selected]=[string]$op.after
 }
 if(@($Plan.operations).Count -eq 0){Copy-Item -LiteralPath $Source -Destination $Destination -Force}
 else{
  $text=($output -join "`r`n")+"`r`n"
  if($enc.GetString($enc.GetBytes($text)) -cne $text){throw 'Texto nao representavel na codificacao do jogo.'}
  [IO.File]::WriteAllText($Destination,$text,$enc)
 }
 return [pscustomobject]@{path=$Plan.path;mode=$(if($exact){'hash'}else{'contexto'});changes=@($Plan.operations).Count}
}
function Apply-ScenePlan([string]$Source,[string]$Destination,$Plan){
 $enc=[Text.Encoding]::GetEncoding(1252)
 $bytes=[IO.File]::ReadAllBytes($Source);$text=$enc.GetString($bytes)
 if(([Convert]::ToBase64String($bytes) -cne [Convert]::ToBase64String($enc.GetBytes($text)))){throw 'Codificacao da cena nao reconhecida.'}
 $map=@{}
 foreach($entry in @($Plan.names)){
  $needle='(?m)NAME='+[regex]::Escape($entry.before)+'(?=[\r\n\x00])'
  if([regex]::Matches($text,$needle).Count -ne 1){throw "Cena modificada ou de versao nao reconhecida: $($Plan.path)."}
  $map[[string]$entry.before]=[string]$entry.after
 }
 $updated=[regex]::Replace($text,'NAME=([^\r\n\x00]*)',[Text.RegularExpressions.MatchEvaluator]{param($m) $key=$m.Groups[1].Value;if($map.ContainsKey($key)){return 'NAME='+$map[$key]};return $m.Value})
 if([regex]::Replace($text,'NAME=[^\r\n\x00]*','NAME=') -cne [regex]::Replace($updated,'NAME=[^\r\n\x00]*','NAME=')){throw 'Alteracao inesperada na cena.'}
 [IO.File]::WriteAllBytes($Destination,$enc.GetBytes($updated))
}
function Resolve-GameFile([string]$GamePath,[string]$Relative){
 if([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)'){throw 'Caminho invalido no pacote.'}
 $root=[IO.Path]::GetFullPath($GamePath).TrimEnd('\')
 $target=[IO.Path]::GetFullPath((Join-Path $root $Relative))
 if(-not $target.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Destino fora da pasta do jogo.'}
 return $target
}

