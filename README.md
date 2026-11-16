# Projecte ISO/FDM · Part individual · Joan Brotons Vidal

**ASIX ThinkLab — "Naix un sistema: instal·la, configura i vigila'l"** (v2.0)
Mòduls **FDM** (RA1, RA4) i **ISO** (RA1, RA3, RA6) · Posició a l'aula **11** → LAN **`192.168.11.0/24`**

Aquest repositori documenta l'**entorn de proves individual** muntat a VirtualBox al portàtil de classe, seguint l'esquema "Muntatge individual" donat pel professor. Tot el que hi ha aquí està comprovat a les màquines: cada afirmació remet a una evidència a [`evidencies/`](evidencies/), presa amb ordres reals (data 16/11/2026). On una dada no es pot comprovar, es marca **N/C** amb la proposta de comprovació.

## Mapa de l'entorn

| Equip | IP LAN | SO / versió | Funció |
|---|---|---|---|
| OPNsense | **192.168.11.1** | OPNsense 26.7 | Passarel·la per defecte, tallafocs, DNS |
| MikroTik | 192.168.11.2 | RouterOS 7.24.5 | Passarel·la alternativa (contingència) |
| Debian + nftables | 192.168.11.3 | Debian 13.1 | Passarel·la alternativa, DNS secundari |
| TrueNAS | **192.168.11.5** | TrueNAS 27.0.0-RC.1 | Servidor de còpies (pool `Copias`, disc de 5 GB) |
| Windows Server | 192.168.11.10 | Windows Server 2025 Standard | Controlador de domini **`joan11.local`** (NetBIOS `JOAN11`) |
| Proxmox VE | **192.168.11.17** | Proxmox VE 9.2.2 | Virtualització (només xarxa, per indicació del professor) |
| Windows 11 | 192.168.11.20 | Windows 11 | Client |
| Ubuntu | 192.168.11.25 | Ubuntu 26.04.1 LTS | Client Linux (+ proves de RAID) |
| Ubuntu Server monitoratge | — | — | Es farà en una tasca posterior |

Només les **WAN dels tres servidors de comunicacions** van per DHCP (adaptador pont a la xarxa de l'aula). **Tots els equips de la LAN tenen IP manual** i a la LAN no hi ha cap servidor DHCP.

## Documentació per tasques (part individual)

| Tasca | Què es demana (individual) | Document |
|---|---|---|
| 0 | Entorn propi, recursos físics i limitacions · Apte+: documentar en Markdown/Git | [docs/T0-entorn-proves.md](docs/T0-entorn-proves.md) |
| 2 | Inventari equip de classe i de casa, colls de botella · Apte+: tests de memòria, disc i xarxa | [docs/T2-inventari-diagnostic.md](docs/T2-inventari-diagnostic.md) |
| 4 | Esquema de xarxa individual i interfícies · Apte+: connectivitat amb proves | [docs/T4-xarxa.md](docs/T4-xarxa.md) |
| 5 | Els mateixos sistemes que el grup al meu entorn | [5.1 Comunicacions](docs/T5-1-comunicacions.md) · [5.2 TrueNAS i còpies](docs/T5-2-truenas-copies.md) · [5.3 Proxmox](docs/T5-3-proxmox.md) · [5.4 Windows Server](docs/T5-4-windows-server.md) · [5.5 Clients](docs/T5-5-clients.md) |
| 6 | Almenys 3 tipus de RAID verificats | [docs/T6-emmagatzematge-raid.md](docs/T6-emmagatzematge-raid.md) |
| 7 | Anàlisi de recursos de la màquina física amb les VM · Apte+: 2 optimitzacions mesurades | [docs/T7-rendiment.md](docs/T7-rendiment.md) |
| 8 | Cas pràctic final i qüestionari | Es fa a classe el 25/11 |

Les tasques 1 i 3 són només de grup i no formen part d'aquest repositori individual.

## Estructura del repositori

```text
docs/         Documentació de cada tasca
evidencies/   Eixides reals d'ordres (logs, proves, mesures)
configs/      Configuracions exportades (sense contrasenyes ni claus privades)
scripts/      Scripts utilitzats per a proves i còpies
```

## Usuaris d'administració

| Equip | Usuari administrador |
|---|---|
| OPNsense | `root` |
| MikroTik | `administrador11` (`admin` desactivat) · `backup` només lectura per a còpies |
| Debian | `administrador11` (sudo) · `root` |
| TrueNAS | `truenas_admin` · `backup_user` (propietari de les còpies) |
| Proxmox | `root@pam` · `administrador11@pam` (rol Administrator) |
| Windows Server | `administrador11` (administrador local → administrador del domini) |
| Ubuntu | `joan11` (sudo) |

Com demana l'enunciat, **les contrasenyes no es guarden al repositori**.

## Ús de la IA

S'ha utilitzat un assistent d'IA (Claude) com a ajuda per a configurar i documentar. Totes les dades d'aquest repositori s'han obtingut executant ordres a les màquines i es poden reproduir amb els scripts de [`scripts/`](scripts/). El README anterior contenia dades inventades: un "SSD Sabrent NVMe" (el disc real és un Kingston A400 per USB), pings a 8.8.8.8 que la xarxa de l'aula no deixa fer, i temperatures i velocitats sense cap mesura. S'han substituït per mesures reals.
