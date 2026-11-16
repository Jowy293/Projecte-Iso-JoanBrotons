# wu.ps1 - busca i instal·la les actualitzacions de qualitat (no les de característiques) amb l'API de Windows Update
$log="C:\Users\Public\wu-log.txt"; function L($m){ "$(Get-Date -Format 'HH:mm:ss') $m" | Tee-Object -Append $log }
L "Inici. Build: $([Environment]::OSVersion.Version)"
$s=New-Object -ComObject Microsoft.Update.Session; $se=$s.CreateUpdateSearcher()
$r=$se.Search("IsInstalled=0 and IsHidden=0 and Type='Software'")
$c=New-Object -ComObject Microsoft.Update.UpdateColl
foreach($u in $r.Updates){ $up=$false; foreach($cat in $u.Categories){ if($cat.Name -match 'Upgrade'){ $up=$true } }
  if($up){ L "OMESA (actualització de característiques): $($u.Title)" } else { L "Trobada: $($u.Title) ($([math]::Round($u.MaxDownloadSize/1MB)) MB)"; if(-not $u.EulaAccepted){$u.AcceptEula()}; [void]$c.Add($u) } }
if($c.Count -eq 0){ L "Res a instal·lar"; exit }
$d=$s.CreateUpdateDownloader(); $d.Updates=$c; L "Descarregant $($c.Count)..."; $dr=$d.Download(); L "Descàrrega: codi $($dr.ResultCode)"
$i=$s.CreateUpdateInstaller(); $i.Updates=$c; L "Instal·lant..."; $ir=$i.Install()
for($k=0;$k -lt $c.Count;$k++){ L "  $($c.Item($k).Title) -> codi $($ir.GetUpdateResult($k).ResultCode)" }
L "Fi. Codi global $($ir.ResultCode) (2=correcte, 3=amb errors). Cal reiniciar: $($ir.RebootRequired)"
