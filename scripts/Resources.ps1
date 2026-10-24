Set-StrictMode -Version 2
if(-not ('FateLocalization.Native' -as [type])){
Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace FateLocalization {
 public class Native {
  public delegate bool LangCallback(IntPtr m,IntPtr t,IntPtr n,ushort l,IntPtr p);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern IntPtr LoadLibraryEx(string p,IntPtr f,uint flags);
  [DllImport("kernel32.dll")] public static extern bool FreeLibrary(IntPtr m);
  [DllImport("user32.dll",CharSet=CharSet.Unicode)] public static extern int LoadString(IntPtr m,uint id,System.Text.StringBuilder s,int size);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern bool EnumResourceLanguages(IntPtr m,IntPtr t,IntPtr n,LangCallback cb,IntPtr p);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern IntPtr BeginUpdateResource(string p,bool delete);
  [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)] public static extern bool UpdateResource(IntPtr h,IntPtr t,IntPtr n,ushort l,byte[] data,uint size);
  [DllImport("kernel32.dll",SetLastError=true)] public static extern bool EndUpdateResource(IntPtr h,bool discard);
 }
}
"@
}
function Build-FateDll([string]$Source,[string]$Destination,$Entries){
 Copy-Item -LiteralPath $Source -Destination $Destination -Force
 $module=[FateLocalization.Native]::LoadLibraryEx($Destination,[IntPtr]::Zero,2)
 if($module -eq [IntPtr]::Zero){throw 'Biblioteca de idioma invalida.'}
 $blocks=@{};$script:ResourceLanguages=@{}
 try{
  foreach($entry in $Entries){
   $buffer=[Text.StringBuilder]::new(16000)
   [void][FateLocalization.Native]::LoadString($module,[uint32]$entry.id,$buffer,$buffer.Capacity)
   $value=$buffer.ToString()
   if($value -cne $entry.text -and $value -cnotin $entry.sources){throw "Biblioteca de idioma de versao desconhecida. Recurso: $($entry.id). Nenhum arquivo do jogo foi alterado."}
   $block=[int][Math]::Floor($entry.id/16)+1
   if(-not $blocks.ContainsKey($block)){$blocks[$block]=@{}}
   $blocks[$block][[int]$entry.id%16]=[string]$entry.text
  }
  foreach($block in $blocks.Keys){
   # Preserve tambem as entradas nao traduzidas do mesmo bloco.
   for($slot=0;$slot -lt 16;$slot++){
    if(-not $blocks[$block].ContainsKey($slot)){
     $buffer=[Text.StringBuilder]::new(16000)
     [void][FateLocalization.Native]::LoadString($module,[uint32](($block-1)*16+$slot),$buffer,$buffer.Capacity)
     $blocks[$block][$slot]=$buffer.ToString()
    }
   }
   $script:ResourceBlock=$block
   $script:ResourceLanguages[$block]=[Collections.Generic.List[uint16]]::new()
   $callback=[FateLocalization.Native+LangCallback]{param($m,$t,$n,$l,$p) $script:ResourceLanguages[$script:ResourceBlock].Add($l);return $true}
   if(-not [FateLocalization.Native]::EnumResourceLanguages($module,[IntPtr]6,[IntPtr]$block,$callback,[IntPtr]::Zero)){throw "Bloco de idioma ausente: $block"}
  }
 }finally{[void][FateLocalization.Native]::FreeLibrary($module)}
 $handle=[FateLocalization.Native]::BeginUpdateResource($Destination,$false)
 if($handle -eq [IntPtr]::Zero){throw 'Nao foi possivel preparar a biblioteca traduzida.'}
 $success=$false
 try{
  foreach($block in $blocks.Keys){
   $stream=[IO.MemoryStream]::new();$writer=[IO.BinaryWriter]::new($stream,[Text.Encoding]::Unicode)
   for($slot=0;$slot -lt 16;$slot++){$value=$blocks[$block][$slot];$writer.Write([uint16]$value.Length);$writer.Write([Text.Encoding]::Unicode.GetBytes($value))}
   $writer.Flush();$data=$stream.ToArray();$writer.Dispose();$stream.Dispose()
   foreach($lang in $script:ResourceLanguages[$block]){if(-not [FateLocalization.Native]::UpdateResource($handle,[IntPtr]6,[IntPtr]$block,$lang,$data,$data.Length)){throw ('Falha ao montar os recursos traduzidos. Win32='+[Runtime.InteropServices.Marshal]::GetLastWin32Error())}}
  }
  $success=$true
 }finally{if(-not [FateLocalization.Native]::EndUpdateResource($handle,(-not $success))){throw ('Falha ao finalizar os recursos traduzidos. Win32='+[Runtime.InteropServices.Marshal]::GetLastWin32Error())}}
 $module=[FateLocalization.Native]::LoadLibraryEx($Destination,[IntPtr]::Zero,2)
 if($module -eq [IntPtr]::Zero){throw 'Biblioteca traduzida nao abre.'}
 try{
  foreach($entry in $Entries){$buffer=[Text.StringBuilder]::new(16000);[void][FateLocalization.Native]::LoadString($module,[uint32]$entry.id,$buffer,$buffer.Capacity);if($buffer.ToString() -cne $entry.text){throw "Verificacao da biblioteca falhou: $($entry.id)"}}
 }finally{[void][FateLocalization.Native]::FreeLibrary($module)}
}

