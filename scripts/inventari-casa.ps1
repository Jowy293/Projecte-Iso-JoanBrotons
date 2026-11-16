# Inventari i proves del PC de casa (Windows 11). Executar en PowerShell com a administrador:
#   Set-ExecutionPolicy -Scope Process Bypass ; .\inventari-casa.ps1
# Genera inventari-casa.txt al mateix directori. Pujar-lo a evidencies/.
$o = "$PSScriptRoot\inventari-casa.txt"
"## Inventari PC casa - $(Get-Date)" | Out-File $o
"### Equip"            | Add-Content $o; Get-CimInstance Win32_ComputerSystem | Select Manufacturer,Model,TotalPhysicalMemory | Format-List | Out-String | Add-Content $o
"### Placa / BIOS"     | Add-Content $o; Get-CimInstance Win32_BaseBoard | Select Manufacturer,Product | Format-List | Out-String | Add-Content $o
Get-CimInstance Win32_BIOS | Select SMBIOSBIOSVersion,ReleaseDate | Format-List | Out-String | Add-Content $o
"### SO"               | Add-Content $o; Get-CimInstance Win32_OperatingSystem | Select Caption,Version,OSArchitecture | Format-List | Out-String | Add-Content $o
"### CPU"              | Add-Content $o; Get-CimInstance Win32_Processor | Select Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,VirtualizationFirmwareEnabled | Format-List | Out-String | Add-Content $o
"### RAM (moduls)"     | Add-Content $o; Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,PartNumber,Capacity,Speed | Format-Table | Out-String | Add-Content $o
"### Discos"           | Add-Content $o; Get-PhysicalDisk | Select FriendlyName,MediaType,BusType,Size,HealthStatus | Format-Table | Out-String | Add-Content $o
"### Xarxa"            | Add-Content $o; Get-NetAdapter | Select Name,InterfaceDescription,LinkSpeed,Status | Format-Table | Out-String | Add-Content $o
"### GPU"              | Add-Content $o; Get-CimInstance Win32_VideoController | Select Name,AdapterRAM | Format-Table | Out-String | Add-Content $o
"### Firmware/arrencada" | Add-Content $o; try { "SecureBoot: $(Confirm-SecureBootUEFI)" | Add-Content $o } catch { "BIOS (Legacy)" | Add-Content $o }
"### TPM"              | Add-Content $o; Get-Tpm | Select TpmPresent,TpmReady | Format-List | Out-String | Add-Content $o
"### PROVA DISC (winsat disk, unitat C:)" | Add-Content $o; winsat disk -drive c | Select-String "Disk" | Out-String | Add-Content $o
"### PROVA MEMORIA (winsat mem)" | Add-Content $o; winsat mem | Select-String "Memory" | Out-String | Add-Content $o
"### PROVA CPU (winsat cpuformal)" | Add-Content $o; winsat cpuformal | Select-String "CPU" | Out-String | Add-Content $o
"Fet. Fitxer: $o"
