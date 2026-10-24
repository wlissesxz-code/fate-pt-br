function Read-OptionalRegistry([string]$Path){try{return Get-ItemProperty -LiteralPath $Path -ErrorAction Stop}catch{return $null}}
function Test-FateFolder([string]$Path){
 if(-not $Path){return $false}
 foreach($relative in @('fate.exe','LANG\en-US.dll','ITEMS\items.dat','SPELLS\spells.dat','MONSTERS\monsters.dat')){if(-not(Test-Path -LiteralPath (Join-Path $Path $relative) -PathType Leaf)){return $false}}
 return $true
}
function Find-FateInstallPaths{
 param([string[]]$AdditionalSteamRoots=@())
 $candidates=[Collections.Generic.List[string]]::new()
 foreach($key in @('HKLM:\SOFTWARE\GOG.com\Games\2050639399','HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\2050639399')){
  if(Test-Path -LiteralPath $key){$p=Read-OptionalRegistry $key;if(-not $p){continue};$property=$p.PSObject.Properties['path'];if($property -and $property.Value){$candidates.Add([string]$property.Value)}}
 }
 foreach($base in @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall','HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall','HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall')){
  foreach($key in @(Get-ChildItem -LiteralPath $base -ErrorAction SilentlyContinue)){
   if($key.PSChildName -in @('Steam App 246840','2050639399_is1')){$p=Read-OptionalRegistry $key.PSPath;if(-not $p){continue};$property=$p.PSObject.Properties['InstallLocation'];if($property -and $property.Value){$candidates.Add([string]$property.Value)}}
  }
 }
 $steamRoots=[Collections.Generic.List[string]]::new()
 foreach($extra in $AdditionalSteamRoots){$steamRoots.Add($extra)}
 foreach($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam')){
  if(Test-Path -LiteralPath $key){$p=Read-OptionalRegistry $key;if(-not $p){continue};foreach($name in @('SteamPath','InstallPath')){$property=$p.PSObject.Properties[$name];if($property -and $property.Value){$steamRoots.Add([string]$property.Value)}}}
 }
 $libraries=[Collections.Generic.List[string]]::new()
 foreach($root in @($steamRoots | Select-Object -Unique)){
  $libraries.Add($root)
  $vdf=Join-Path $root 'steamapps\libraryfolders.vdf'
  if(Test-Path -LiteralPath $vdf){foreach($m in [regex]::Matches([IO.File]::ReadAllText($vdf),'"path"\s+"((?:\\.|[^"])*)"')){$libraries.Add($m.Groups[1].Value.Replace('\\','\'))}}
 }
 foreach($library in @($libraries | Select-Object -Unique)){
  $acf=Join-Path $library 'steamapps\appmanifest_246840.acf'
  if(Test-Path -LiteralPath $acf){$m=[regex]::Match([IO.File]::ReadAllText($acf),'"installdir"\s+"([^"]+)"');if($m.Success){$candidates.Add((Join-Path $library ('steamapps\common\'+$m.Groups[1].Value)))}}
 }
 return @($candidates | Where-Object {Test-FateFolder $_} | ForEach-Object {[IO.Path]::GetFullPath($_).TrimEnd('\')} | Select-Object -Unique)
}
function Select-FateFolder([string]$GamePath){
 if($GamePath){if(-not(Test-FateFolder $GamePath)){throw 'A pasta escolhida nao contem o FATE classico com os arquivos de idioma ingles.'};return [IO.Path]::GetFullPath($GamePath).TrimEnd('\')}
 $found=@(Find-FateInstallPaths)
 if($found.Count -eq 1){Write-Host "Jogo encontrado: $($found[0])";return $found[0]}
 if($found.Count -gt 1){
  for($i=0;$i -lt $found.Count;$i++){Write-Host "$($i+1). $($found[$i])"}
  $choice=Read-Host 'Qual instalacao deseja traduzir? Informe o numero'
  $number=0;if(-not [int]::TryParse($choice,[ref]$number) -or $number -lt 1 -or $number -gt $found.Count){throw 'Escolha invalida.'}
  return $found[$number-1]
 }
 Add-Type -AssemblyName System.Windows.Forms
 $dialog=[System.Windows.Forms.FolderBrowserDialog]::new();$dialog.Description='Selecione a pasta do FATE classico que contem fate.exe';$dialog.ShowNewFolderButton=$false
 try{if($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK){throw 'Selecao cancelada.'};$selected=$dialog.SelectedPath}finally{$dialog.Dispose()}
 if(-not(Test-FateFolder $selected)){throw 'A pasta escolhida nao e uma instalacao reconhecida do FATE classico.'}
 return $selected
}


