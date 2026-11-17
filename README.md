# Projecte ISO/FDM · Part individual · Joan Brotons Vidal

**ASIX ThinkLab — "Naix un sistema: instal·la, configura i vigila'l"** (v2.0)
Mòduls **FDM** (RA1, RA4) i **ISO** (RA1, RA3, RA6) · Posició a l'aula **11** → LAN **`192.168.11.0/24`**

Aquest repositori documenta l'**entorn de proves individual** muntat a VirtualBox al portàtil de classe, seguint l'esquema "Muntatge individual" donat pel professor. Tot el que hi ha aquí està comprovat a les màquines: cada afirmació remet a una evidència a [`evidencies/`](evidencies/), presa amb ordres reals (data 16/11/2026). On una dada no es pot comprovar, es marca **N/C** amb la proposta de comprovació.

## Mapa de l'entorn

| Equip | IP LAN | SO / versió | Funció |
|---|---|---|---|
| OPNsense | **192.168.11.1** | OPNsense 26.7 | Passarel·la per defecte, tallafocs |
| MikroTik | 192.168.11.2 | RouterOS 7.24.5 | Passarel·la alternativa (contingència) |
| Debian + nftables | 192.168.11.3 | Debian 13.1 | Passarel·la alternativa |
| TrueNAS | **192.168.11.5** | TrueNAS 27.0.0-RC.1 | Servidor de còpies (pool `Copias`, disc de 5 GB) |
| Windows Server | 192.168.11.10 | Windows Server 2025 Standard | Controlador de domini **`joan11.local`** (NetBIOS `JOAN11`), nom `DC-JOAN11` |
| Proxmox VE (pve1, pve2, pve3) | **192.168.11.17**, .18, .19 | Proxmox VE 9.2.2 | Clúster de virtualització `clusterjoan11` de 3 nodes (sense màquines a dins) |
| Windows 11 | 192.168.11.20 | Windows 11 Pro 23H2 (TPM 2.0 + Secure Boot) | Client (`W11-CLIENT11`), unit al domini `joan11.local` |
| Ubuntu | 192.168.11.25 | Ubuntu 26.04.1 LTS | Client Linux (+ proves de RAID) |

Només les **WAN dels tres servidors de comunicacions** van per DHCP (adaptador pont a la xarxa de l'aula). **Tots els equips de la LAN tenen IP manual** i a la LAN no hi ha cap servidor DHCP.

## Lliurament per tasques (part individual)

Un fitxer per cada lliurament d'Aules:

| Tasca | Què es demana (individual) | Document |
|---|---|---|
| 0 | Entorn de proves propi · Apte+: documentar-lo en Markdown/Git (esquema de VM, recursos i problemes) | [Tasca0.md](Tasca0.md) |
| 2 | Inventari de l'equip de classe i de casa i colls de botella · Apte+: tests de memòria, disc i xarxa | [Tasca2.md](Tasca2.md) |
| 4 | Esquema de xarxa individual · Apte+: verificar la connectivitat amb evidències | [Tasca4.md](Tasca4.md) |
| 5 | Els mateixos sistemes que el grup al meu entorn · Apte+: sistema de còpies dels servidors crítics | [Tasca5.md](Tasca5.md) |
| 6 | Almenys 3 tipus de RAID · Apte+: RAID 1 entre discos de dos equips | [Tasca6.md](Tasca6.md) |
| 7 | Anàlisi de recursos de la màquina física · Apte+: dues optimitzacions mesurades | [Tasca7.md](Tasca7.md) |

La Tasca 8 (cas pràctic i qüestionari) es fa a classe el 25/11.

## Estructura del repositori

```text
Tasca0.md … Tasca7.md   Un document per lliurament (les tasques 1 i 3 no tenen part individual)
diagrames/              Esquemes de xarxa (SVG)
evidencies/             Eixides reals d'ordres (logs, proves, mesures)
evidencies/captures/    Captures de pantalla de les VM
configs/                Configuracions exportades (sense contrasenyes ni claus privades)
scripts/                Scripts utilitzats per a proves i còpies
```

## Usuaris d'administració

| Equip | Usuari administrador |
|---|---|
| OPNsense | `root` |
| MikroTik | `administrador11` (`admin` desactivat) |
| Debian | `administrador11` (sudo) · `root` |
| TrueNAS | `truenas_admin` · `backup_user` (propietari de les còpies) |
| Proxmox (3 nodes) | `root@pam` · `administrador11@pam` (rol Administrator) |
| Windows Server | `JOAN11\administrador11` (administrador del domini) |
| Windows 11 | `Administracion11` (administrador local) · `Cliente11` (usuari estàndard) |
| Ubuntu | `joan11` (sudo) |

Com demana l'enunciat, **les contrasenyes no es guarden al repositori**.
