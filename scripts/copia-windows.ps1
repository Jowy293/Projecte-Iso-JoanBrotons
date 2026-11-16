# copia-windows.ps1 — Còpia de la configuració d'un equip Windows al TrueNAS (\\192.168.11.5\backups\<Desti>)
# Ús (PowerShell com a administrador):
#   powershell -ExecutionPolicy Bypass -File copia-windows.ps1 -Desti winserver -Pw <contrasenya de backup_user>
param([Parameter(Mandatory)][string]$Desti, [Parameter(Mandatory)][string]$Pw)

$eq   = $env:COMPUTERNAME
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'
$dir  = "C:\CopiaConfig\$eq-$stamp"
New-Item -ItemType Directory -Force $dir | Out-Null

# 1. Xarxa
ipconfig /all                                   > "$dir\xarxa-ipconfig.txt"
Get-NetIPConfiguration -Detailed | Out-String   > "$dir\xarxa-netipconfiguration.txt"
route print                                     > "$dir\xarxa-rutes.txt"
Get-DnsClientServerAddress | Out-String         > "$dir\xarxa-dns.txt"
# 2. Identitat i usuaris
Get-ComputerInfo -Property OsName,OsVersion,OsBuildNumber,CsName,CsDomain,WindowsProductName | Out-String > "$dir\sistema.txt"
Get-LocalUser | Select-Object Name,Enabled,LastLogon,PasswordRequired | Out-String > "$dir\usuaris-locals.txt"
if ((Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4) {   # 4-5 = controlador de domini: no té grups locals
    Get-ADGroupMember -Identity 'S-1-5-32-544' | Out-String                       > "$dir\administradors.txt"
} else {
    Get-LocalGroupMember -SID S-1-5-32-544 | Out-String                           > "$dir\administradors.txt"
}
# 3. Rols (només servidor), actualitzacions i programari instal·lat
if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) {
    Get-WindowsFeature | Where-Object Installed | Select-Object Name,DisplayName | Out-String > "$dir\rols-caracteristiques.txt"
}
Get-HotFix | Sort-Object InstalledOn | Out-String > "$dir\actualitzacions.txt"
Get-ItemProperty 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*','HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' |
    Where-Object DisplayName | Select-Object DisplayName,DisplayVersion,Publisher | Sort-Object DisplayName |
    Export-Csv "$dir\programari.csv" -NoTypeInformation -Encoding UTF8
# 4. Seguretat: tallafocs (reimportable) i polítiques locals
netsh advfirewall export "$dir\tallafocs.wfw" | Out-Null
secedit /export /cfg "$dir\politiques-seguretat.inf" /quiet
reg export 'HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' "$dir\tcpip.reg" /y | Out-Null

# 5. Comprimir i enviar al TrueNAS per SMB
$zip = "C:\CopiaConfig\$eq-config-$stamp.zip"
Compress-Archive -Path "$dir\*" -DestinationPath $zip -Force
net use \\192.168.11.5\backups /user:backup_user $Pw | Out-Null
New-Item -ItemType Directory -Force "\\192.168.11.5\backups\$Desti" | Out-Null
Copy-Item $zip "\\192.168.11.5\backups\$Desti\" -Force
$remot = Get-Item "\\192.168.11.5\backups\$Desti\$(Split-Path $zip -Leaf)"
"Fitxer al TrueNAS : $($remot.FullName)"
"Mida              : $([math]::Round($remot.Length/1KB,1)) KB"
"SHA-256 local     : $((Get-FileHash $zip).Hash)"
"SHA-256 al NAS    : $((Get-FileHash $remot.FullName).Hash)"
Get-ChildItem $dir | Select-Object Name,Length | Format-Table -AutoSize
net use \\192.168.11.5\backups /delete /y | Out-Null
