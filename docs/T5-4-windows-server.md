# Tasca 5.4 · Windows Server 2025 · Controlador de domini `joan11.local` (`192.168.11.10`)

**RA:** ISO RA1 d-h · ISO RA3 (còpia)

> Per indicació del professor, el Windows Server, que a l'arquitectura de referència va dins del clúster Proxmox, s'ha instal·lat **com a VM de VirtualBox independent** per falta de recursos per a la virtualització imbricada.

## 1. Instal·lació

| Ítem | Valor |
|---|---|
| ISO | `WinServer.iso` → *Windows Server 2025 Standard Evaluation (experiència d'escriptori)*, build **10.0.26100.32230**, es-ES (detectat amb `VBoxManage unattended detect`) |
| Requisits oficials | CPU x64 1,4 GHz amb SLAT, 512 MB RAM (2 GB amb escriptori), 32 GB de disc, TPM 2.0 i UEFI/Secure Boot **recomanats** però no obligatoris (a diferència de Windows 11) |
| Recursos assignats | 2 vCPU, 3 GB RAM, disc de 50 GB (marcat SSD, amb TRIM), BIOS |
| Llicència | Avaluació de 180 dies (no necessita clau) |
| Nom d'equip | `DC-JOAN11` |
| Usuari d'administració | `administrador11` (administrador local; en promocionar a DC passa a ser administrador del domini). `Administrador` integrat desactivat per Windows |

### Incidència d'instal·lació real (punt 5 de la tasca): símptoma → hipòtesi → comprovació → solució

| Pas | Detall |
|---|---|
| **Estat inicial** | La VM antiga (`Windows Server(Claster)`) tenia el Windows instal·lat però **cap configuració de xarxa i una contrasenya desconeguda** (cap de les contrasenyes conegudes funcionava). Com que no tenia res configurat, es decideix reinstal·lar en lloc de forçar l'accés |
| **Símptoma 1** | Instal·lació desatendida (`VBoxManage unattended install`) amb firmware **EFI**: l'instal·lador es queda en "18 % completat" durant més de 30 min, el disc USB de l'amfitrió llegeix contínuament a **~293 MB/s** (85-90 % d'utilització) i la VM no respon a `pause` ni a `poweroff` (estat `stopping`) |
| Hipòtesi | Les VM no són: els comptadors d'E/S de cada VM (`VBoxManage debugvm … statistics`) donen 0 MB/s. Per tant, el procés `VBoxHeadless` de la VM està bloquejat en una E/S de l'amfitrió |
| Comprovació | Amb `/proc/diskstats` es mesura sda3 abans i després d'aturar la VM: **293 MB/s → 0 MB/s** en matar el procés `VBoxHeadless` del Windows Server. Causa confirmada |
| **Símptoma 2** | Reinstal·lació amb **BIOS**: l'instal·lador s'atura a "Seleccionar ubicació" amb l'error *"Error al seleccionar esta partición para instalarla"* |
| Hipòtesi | La plantilla de VirtualBox crea la partició però **no la formata ni la marca activa** (no té `<ModifyPartitions>`) |
| Comprovació | `autounattend.xml` generat: només `CreatePartition`. A més, `dir A:\` a la consola de WinPE (Shift+F10) mostra que l'instal·lador llig la còpia **del disquet A:** (11 014 bytes, sense corregir) abans que la de la unitat E: (11 236 bytes, corregida) |
| **Solució** | Des de la consola de WinPE: `diskpart` (clean, MBR, partició primària, `format fs=ntfs quick`, `active`, `assign letter=C`) → `dism /Apply-Image /ImageFile:D:\sources\install.wim /Index:2 /ApplyDir:C:\` → `bcdboot C:\Windows /s C: /f BIOS` → copiar `autounattend.xml` a `C:\Windows\Panther\unattend.xml`, perquè les fases *specialize* i *oobeSystem* creen l'usuari, el nom i la IP |
| Retorn | Si la nova instal·lació fallava, la VM es pot tornar a crear igual (disc nou de 50 GB). No hi havia dades a perdre |
| Temps | Diagnòstic ~20 min. Aplicació de la imatge amb DISM ~25 min (limitada pel disc USB) |

## 2. Què és un domini i què aporta a l'empresa

Un **domini Active Directory** és una base de dades centralitzada (al controlador de domini) amb tots els **usuaris, grups, equips i polítiques** de l'organització. Els equips units al domini deleguen l'autenticació al DC (Kerberos), de manera que un usuari té **un sol compte** per a tots els equips i recursos.

Què aporta a l'empresa de l'enunciat (direcció, administració, comercial, producció i informàtica):

| Sense domini (grup de treball) | Amb domini `joan11.local` |
|---|---|
| Un compte local diferent a cada PC; canviar una contrasenya vol dir anar equip per equip | Un compte per persona, creat una vegada; si algú se'n va, es desactiva i perd l'accés a tot |
| Els permisos de les carpetes compartides s'han de repetir a cada servidor | Permisos per **grups** (G_Comercial, G_Direccio…) aplicats a tots els recursos |
| Configuració manual de cada PC | **GPO**: fons, unitats de xarxa mapades, bloqueig d'USB, actualitzacions, contrasenyes segures… aplicades automàticament per OU |
| No hi ha registre central de qui entra on | Auditoria centralitzada d'inicis de sessió |
| — | DNS intern integrat (`joan11.local`) |

**Inconvenients acceptats:** el DC es converteix en un punt crític. Si cau, no es pot iniciar sessió en equips nous i el DNS intern deixa de respondre. A producció en caldrien dos, i aquí només n'hi ha un. També costa llicències (CAL) i administració.

Per enunciat, la implantació completa (OU, GPO, unió de clients) correspon als RA4/RA5 posteriors: aquí es crea el domini i es deixa preparat.
