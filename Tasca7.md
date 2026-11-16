# Tasca 7 · Rendiment i diagnòstic

**Alumne:** Joan Brotons Vidal · Posició 11 · **RA:** ISO RA6 a-h · FDM RA1 e-g

| Què demana l'enunciat (individual) | On està |
|---|---|
| **Obligatori:** analitzar els recursos de la màquina física, comprovar quines VM saturen més un recurs o un altre, i fer un informe del que es satura en treballar amb cada màquina i de quantes VM es poden arrancar i fer servir sense bloquejar l'equip físic | §1, §2, §3 |
| **Apte+:** proposar i aplicar almenys dues optimitzacions a la configuració de les VM (recursos, serveis, arrencada…) i demostrar la millora amb mesures | §4 |

---

## 1. Com s'ha mesurat

| Què | Eina | Script / evidència |
|---|---|---|
| CPU (us, sy, id, wa), RAM, swap | `vmstat`, `free` | [`scripts/mesura-host.sh`](scripts/mesura-host.sh) |
| Disc de l'amfitrió (MB/s i % d'utilització) | `/proc/diskstats` (camps de sectors llegits/escrits i temps d'E/S de `sda`) | ídem |
| Xarxa | `/proc/net/dev` (`eno1`) | ídem |
| Temperatura | `/sys/class/thermal` (`x86_pkg_temp`) | ídem |
| E/S de cada VM per separat | `VBoxManage debugvm <vm> statistics` (bytes llegits pel disc virtual) | — |

Línia base de l'amfitrió (portàtil ASUS B3605CCA, Core Ultra 5 125H, 32 GB, SSD SATA per USB 3.0): vegeu la [Tasca 2](Tasca2.md).

## 2. Mesures

| Escenari | VM enceses | CPU lliure | RAM disponible | Disc `sda` (USB) | Temp. CPU | Evidència |
|---|---|---|---|---|---|---|
| Instal·lació del Windows Server | 7 (WS instal·lant) | 86-90 % | 11,5 GB | **~290 MB/s de lectura, 85 % d'ús** | — | [`t7-carrega-instalacio-winserver.txt`](evidencies/t7-carrega-instalacio-winserver.txt) |
| **Totes les VM enceses** (WS i W11 arrencant) | **8** | 87,5 % (wa 4,4 %) | **6,3 GB** de 31,3 GB · swap 0 | 25 MB/s d'escriptura, **87 % d'ús** | 73 °C | [`t7-8vm-enceses.txt`](evidencies/t7-8vm-enceses.txt) |
| WS congelat per TRIM (vegeu §4) | 6 | ~92 % | 12,9 GB | **277 MB/s de lectura, 91 % d'ús** | — | [`t7-optimitzacio-discard.txt`](evidencies/t7-optimitzacio-discard.txt) |

## 3. Informe: què se satura i quantes VM es poden fer servir

**Què se satura:**
- **El disc és l'únic recurs que se satura.** En tots els escenaris amb càrrega arriba al 85-91 % d'utilització. La CPU continua al 86-92 % lliure, i la RAM no arriba mai a la swap.
- **Les VM que més disc consumeixen són les Windows** (Server 2025 i 11). En instal·lar, arrencar, actualitzar o fer TRIM fan lectures sostingudes de prop de 300 MB/s, que és el màxim de l'SSD per USB. Mentre passa això, la resta de VM i l'escriptori de l'amfitrió van lents.
- **Les que més RAM ocupen** són també les Windows (3 i 4 GB) i l'OPNsense (3 GB). Les Linux, el TrueNAS i el MikroTik estan entre 512 MB i 2 GB.
- **La CPU no és mai el problema:** 18 fils per a 11 vCPU en total.

**Quantes VM es poden arrancar:**
- **Les 8 VM caben a la vegada** (18,5 GB assignats). El portàtil no es bloqueja, però el disc va al 87 % i queden 6,3 GB de RAM per a l'amfitrió.
- **Per a treballar còmodament: 5-6 VM enceses**, és a dir, els servidors de comunicacions necessaris, el TrueNAS i la VM amb què s'està treballant. Les altres es guarden en estat (*savestate*), que no consumeix ni RAM ni CPU.
- **No s'ha d'arrancar ni actualitzar dos Windows alhora:** són les dues VM que saturen el disc.

## 4. Optimitzacions (Apte+)

### 4.1 Optimització 1: desactivar *discard/TRIM* al disc del Windows Server

| | Detall |
|---|---|
| **Problema** | El Windows Server es quedava congelat (pantalla i rellotge aturats) a la fase *specialize*, al primer inici de sessió i a l'escriptori. Mentrestant, el disc de l'amfitrió llegia contínuament a ~277 MB/s amb el 91 % d'ús |
| **Diagnòstic** | Les estadístiques de VirtualBox mostren que el disc virtual del WS **no llegeix res** (0 MB/s). Per tant, la lectura no la fa Windows sinó el procés de VirtualBox. En matar aquest procés, la lectura de l'amfitrió baixa de 245 MB/s a 0. La configuració del disc té `discard=on` sobre un VDI **dinàmic**: quan Windows llança el TRIM (ho fa després d'instal·lar i en optimitzar unitats), VirtualBox llig el fitxer `.vdi` per alliberar blocs i la VM queda bloquejada esperant |
| **Canvi** | `VBoxManage storageattach WinServer2025-DC … --nonrotational on --discard off` |
| **Resultat mesurat** | **Abans:** 277 MB/s de lectura sostinguda, 91 % d'ús i VM congelada. **Després:** la instal·lació dels rols AD DS i DNS, la promoció a controlador de domini i dos reinicis s'han fet sense cap bloqueig, amb el disc de l'amfitrió a ~28 MB/s durant la instal·lació |
| **Inconvenient acceptat** | El VDI no s'encongeix sol quan s'esborren fitxers dins de Windows. Si cal recuperar espai, es fa a mà amb la VM aturada (`VBoxManage modifymedium --compact`) |

Evidència: [`evidencies/t7-optimitzacio-discard.txt`](evidencies/t7-optimitzacio-discard.txt)

### 4.2 Optimització 2

> **Pendent de mesurar.** Proposta: ajustar la RAM assignada al consum real de cada VM (mesurat des de dins de cada sistema) i fer arrencar per torns, per reduir la RAM ocupada amb totes les VM enceses i deixar més memòria cau de disc a l'amfitrió. Es demostrarà amb la mateixa mesura de l'escenari "8 VM" abans i després.
