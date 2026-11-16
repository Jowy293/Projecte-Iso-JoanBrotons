# Tasca 2 · Equips i perifèrics

**Alumne:** Joan Brotons Vidal · Posició 11 · **RA:** FDM RA1 a-h

| Què demana l'enunciat (individual) | On està |
|---|---|
| **Obligatori:** inventari de l'equip de classe i del de casa, comparativa, colls de botella i possibles solucions | apartats 1 i 2 |
| **Apte+:** tests de diagnòstic de memòria, disc i xarxa als dos equips (eina, condicions i resultat), justificant amb les dades si els colls de botella es confirmen o no | apartat 3 |

---

## 1. Inventari

### 1.1 Equip de classe (dades reals)
Obtingut el 16/11/2026 amb `lscpu`, `free`, `lsblk`, `lsusb -t`, `lspci`, `/sys/class/dmi` i `/sys/class/thermal`. Eixida completa: [`evidencies/inventari-host-classe.txt`](evidencies/inventari-host-classe.txt)

| Component | Equip de classe |
|---|---|
| Model | ASUS ExpertBook **B3605CCA** (BIOS B3605CCA.303, 06/11/2025) |
| Format | Portàtil 16" amb bateria (fa de SAI en un tall de llum) |
| SO amfitrió | Linux Mint 22.3, nucli 6.8.0-147 |
| CPU | Intel **Core Ultra 5 125H** · 14 nuclis (4P + 8E + 2LPE) / 18 fils · 400 MHz-4,5 GHz · L3 18 MB · **VT-x** |
| RAM | **32 GB** (31,3 GB útils) + 16 GB swap + 7,6 GB zram |
| Disc del sistema i de les VM | **Kingston A400 SATA 480 GB (SA400S37480G) dins d'una caixa USB 3.0** · controlador `uas` · enllaç **5 Gbit/s** · particions: EFI 509 MB, `/` 58,6 GB, `/home` 388 GB (ext4) |
| Disc intern | Samsung NVMe 1 TB (MZVMA1T0HCLD) · del centre, **no s'utilitza** per a les pràctiques |
| Gràfica | Intel Arc Graphics (Meteor Lake-P, integrada) |
| Xarxa | Ethernet **Intel e1000e 1 Gbit/s** (`eno1`) · Wi-Fi 6 Realtek RTL8852BE |
| USB | Thunderbolt 4 + USB 3.2 Gen 2 |
| Firmware | UEFI |
| Temperatura en repòs amb 5 VM | CPU 68 °C (`x86_pkg_temp`) |

### 1.2 Equip de casa (dades reals)
Obtingut el 16/11/2026 arrencant l'equip de casa amb el mateix disc USB de classe (Linux Mint 22.3), amb `lscpu`, `free`, `lsblk`, `lsusb`, `lspci`, `/sys/class/dmi`, `/sys/class/nvme`, `/sys/class/tpm`, `mokutil` i `sensors`. Eixida completa: [`evidencies/t2-inventari-casa.txt`](evidencies/t2-inventari-casa.txt)

| Component | Equip de casa |
|---|---|
| Model | Sobretaula · placa **ASUS PRIME B650M-A II** (socket AM5, BIOS AMI 3287, 20/09/2025) |
| Format | **Sobretaula** sense bateria (un tall de llum l'apaga si no té SAI) |
| SO habitual | Windows 11 Pro (al disc NVMe intern) |
| CPU | **AMD Ryzen 5 7600X** · 6 nuclis / 12 fils · 545 MHz-5,45 GHz · L2 6 MB · L3 32 MB · **AMD-V** |
| RAM | **32 GB DDR5** (31,3 GB útils) + 16 GB swap. Mòduls i velocitat: N/C (cal `dmidecode -t memory` com a root o CPU-Z a Windows) |
| Disc intern | **KIOXIA EXCERIA PLUS G3 1 TB NVMe** · firmware ELFA01.2 · enllaç **PCIe 4.0 x4 (16 GT/s)** · partició Windows NTFS de 930 GB **ocupada al 87 %** (128 GB lliures) |
| Disc de les VM (si s'arrenca el de classe) | El mateix Kingston A400 en caixa USB (pont JMicron JMS561U, `uas`) · enllaç **5 Gbit/s** encara que el port de la placa és USB 3.2 de 10 Gbit/s |
| Gràfica | NVIDIA (PCI 10de:2d04, dedicada) + AMD Radeon integrada (Raphael) |
| Xarxa | Ethernet **Realtek RTL8125 2.5GbE** (`r8169`) · negocia a **1000 Mbit/s full duplex** amb el router de casa |
| Firmware | **UEFI · Secure Boot activat · TPM 2.0** (fTPM) |
| Perifèrics | 2 teclats USB, ratolí sense fil Logitech (receptor USB), auriculars Logitech G435, teclat MIDI Medeli K66, controlador LED ASUS AURA |
| Temperatura en repòs | CPU 40 °C (`Tctl`) · NVMe 26 °C |

### 1.3 Comparativa

| Recurs | Classe (portàtil ASUS) | Casa (sobretaula) | Qui guanya per a l'entorn de VM |
|---|---|---|---|
| CPU | Core Ultra 5 125H · 14 nuclis / **18 fils** · fins a 4,5 GHz · portàtil (límit de consum i temperatura) | Ryzen 5 7600X · 6 nuclis / **12 fils** · fins a 5,45 GHz · sobretaula | Empat pràctic: les 8 VM sumen 11 vCPU i caben a tots dos. El de casa és més ràpid per nucli i no té límit tèrmic de portàtil; el de classe té més fils |
| RAM | 32 GB | 32 GB DDR5 | **Empat**: el mateix límit de VM simultànies (~18,5 GB per a les 8 VM) |
| **Disc de les VM** | SSD **SATA dins d'una caixa USB 3.0** · `fio`: 401 MB/s seqüencial, 20,3k IOPS 4K | **NVMe PCIe 4.0 intern** · lectura mesurada ≥ 972 MB/s (límit del controlador NTFS de Linux, vegeu l'apartat 3.2) i latència 4K de 94 µs davant de 276 µs | **Casa, de molt**, però només si les VM es guarden al NVMe. Si s'arrenca el disc USB de classe, el coll de botella és el mateix |
| Xarxa | Intel 1 Gbit/s · Internet del centre compartit (81-101 Mbit/s) | Realtek 2,5 Gbit/s (a 1 Gbit/s) · Internet de casa (~490 Mbit/s) | Casa |
| Firmware | UEFI | UEFI · Secure Boot · TPM 2.0 | Empat (tots dos compleixen els requisits de Windows 11) |
| Alimentació | Bateria (fa de SAI) | Sense bateria | Classe |

## 2. Colls de botella

### 2.1 Equip de classe
| Recurs | Previsió | Comprovació | Conclusió |
|---|---|---|---|
| **Disc** | Les VM viuen en un SSD SATA connectat per USB 3.0. El límit teòric és ~450 MB/s (5 Gbit/s menys la sobrecàrrega de UAS) i, en la pràctica, el que done l'A400 | Prova de disc (apartat 3) + mesura durant la instal·lació del Windows Server: **~290 MB/s de lectura sostinguda amb el disc al 85-90 % d'utilització** ([`t7-carrega-instalacio-winserver.txt`](evidencies/t7-carrega-instalacio-winserver.txt)) | **CONFIRMAT, és el coll de botella principal.** Quan una VM fa E/S intensiva (instal·lació, actualitzacions), la resta van lentes |
| RAM | 18,5 GB per a totes les VM + ~6 GB de l'amfitrió (navegador, editor) | Amb 5 VM enceses: 19,8 GB usats, 11,5 GB disponibles, swap 0 | No és coll de botella fins a ~8 VM. A partir d'ahí l'amfitrió es queda sense memòria cau i augmenta l'E/S de disc |
| CPU | 18 fils sobrats per a VM de 1-2 vCPU | Amb 5-6 VM: **86-91 % de CPU lliure** | **DESCARTAT** |
| Tèrmic | Portàtil prim amb càrrega sostinguda | 68 °C amb 5 VM i una instal·lació en curs, sense *throttling* observat | No observat amb aquesta càrrega (al README antic es parlava de 92 °C sense cap mesura) |
| Xarxa | Gigabit Ethernet | La WAN de les VM va en pont: el que limita és la xarxa de l'aula, no la NIC | No és coll de botella per a l'entorn |

**Solucions aplicades / proposades (ajustades al maquinari disponible):**
1. Encendre les VM per torns i **guardar l'estat** de les que no s'utilitzen. Una VM guardada no consumeix ni RAM ni CPU.
2. No instal·lar ni actualitzar dues VM alhora.
3. Ajustar la RAM de cada VM al que consumeix de veritat ([Tasca 7](Tasca7.md)).
4. Millora de maquinari recomanada: treballar en un **SSD NVMe en caixa USB 3.2 Gen 2 (10 Gbit/s)** o en un SSD intern. És el que donaria més rendiment per euro invertit, molt per davant de més RAM o més CPU.

### 2.2 Equip de casa
| Recurs | Previsió | Comprovació (apartat 3.2) | Conclusió |
|---|---|---|---|
| Disc | NVMe intern molt més ràpid que l'SSD USB | `fio`: el disc USB dona 401 MB/s i 20,3k IOPS a l'equip de casa, pràcticament el mateix que a classe. El NVMe llig a ≥ 972 MB/s amb latència 4K tres vegades menor | **Confirmat:** si s'arrenca el disc USB de classe, el coll de botella és el **disc USB**, no l'equip. El port de la placa admet 10 Gbit/s però la caixa només negocia 5 Gbit/s |
| Disc (espai) | — | La partició del NVMe està al **87 %** (128 GB lliures) | **Coll de botella nou detectat.** Les 8 VM ocupen ~190 GB a `/home`: no caben al NVMe sense alliberar espai. A més, un SSD ple perd rendiment d'escriptura |
| RAM | 32 GB, igual que a classe | `memtester` 3,9 GB sense errors. Amb l'escriptori obert queden 27 GB disponibles | Mateix límit que a classe (~8 VM). No previst amb 5-6 VM enceses |
| CPU | 12 fils per a 11 vCPU | — | No previst: les VM estan la major part del temps en repòs. És més ràpida per nucli que la del portàtil |
| Xarxa | NIC de 2,5 Gbit/s | Negocia a 1 Gbit/s (el router de casa és Gigabit). Internet ~490 Mbit/s sostinguts, 0 % de pèrdua | **No és coll de botella** |
| Alimentació | Sense bateria | — | Risc de corrompre els discos de les VM en un tall de llum |

**Solucions proposades:**
1. Per a treballar a casa amb rendiment, **copiar les VM al NVMe** i executar-les amb VirtualBox a Windows. Abans cal **alliberar espai** (com a mínim 200 GB lliures per a les VM i perquè l'SSD no estiga ple).
2. Si es continua arrencant el disc de classe, el que es guanyaria és una caixa USB 3.2 Gen 2 (10 Gbit/s) amb un SSD NVMe, perquè el port de la placa ja és de 10 Gbit/s.
3. RAM: les mateixes mesures que a classe (ajustar la RAM de cada VM i guardar en estat les que no s'utilitzen). Si calguera més, la placa té 4 ranures DDR5.
4. Alimentació: un SAI xicotet o, almenys, no deixar VM enceses sense supervisió.

## 3. Proves de diagnòstic (Apte+)

### 3.1 Equip de classe

Les eines s'han descarregat dels repositoris d'Ubuntu (`apt-get download`) i s'han executat des d'una carpeta d'usuari, sense instal·lar res al sistema del centre.

| Prova | Eina i condicions | Resultat | Interpretació |
|---|---|---|---|
| **Memòria** | `memtester 4.6.0`, 2 GB bloquejats amb `mlock`, 1 passada completa, amb 6 VM enceses (16/11/2026 12:35) | **18 de 18 proves `ok`, 0 errors** (Stuck Address, Random Value, Compare XOR/SUB/MUL/DIV/OR/AND, Sequential Increment, Solid Bits, Block Sequential, Checkerboard, Bit Spread, Bit Flip, Walking Ones/Zeroes, 8/16-bit Writes). Durada: 6 min 17 s | La RAM no té errors. Com que hi havia ~22 GB ocupats per les VM, la prova cobreix una part de la memòria física diferent de la que ja usaven les VM. Evidència: [`evidencies/t2-memtester-classe.txt`](evidencies/t2-memtester-classe.txt) |
| **Xarxa (enllaç)** | `/sys/class/net/eno1`, `ip -s link` | **1000 Mbit/s full duplex**, 0 errors i 0 paquets descartats en 2,3 milions de paquets rebuts | La NIC i el cable funcionen bé |
| **Xarxa (latència)** | `ping -c100 -i0.2` al router de l'aula `172.16.222.1` | **0 % de pèrdua**, mitjana 0,50 ms (mín. 0,44 / màx. 0,64 ms, desviació 0,03 ms) | Xarxa local estable, sense pèrdues ni variacions |
| **Xarxa (Internet)** | `curl` descarregant fitxers grans de `deb.debian.org` i `archive.ubuntu.com` a `/dev/null` (sense escriure al disc) | **81-101 Mbit/s** | Un enllaç Gigabit podria donar ~940 Mbit/s: el límit és l'eixida a Internet del centre, compartida per tota l'aula, no el portàtil. Evidència: [`evidencies/t2-xarxa-classe.txt`](evidencies/t2-xarxa-classe.txt) |
| **Disc** | Mesura amb `/proc/diskstats` durant una càrrega real (instal·lació del Windows Server amb 6 VM enceses) | **~290 MB/s de lectura sostinguda amb el disc al 85-90 % d'utilització** | Confirma el coll de botella: és el màxim pràctic de l'SSD SATA dins de la caixa USB 3.0. Evidència: [`evidencies/t7-carrega-instalacio-winserver.txt`](evidencies/t7-carrega-instalacio-winserver.txt) |

| **Disc (sintètica)** | `fio 3.36` sobre el mateix disc USB, amb les VM aturades (fet a l'equip de casa, apartat 3.2) | 401 MB/s de lectura i 392 MB/s d'escriptura seqüencial | El disc no pot donar més: a classe, durant la instal·lació del Windows Server, ja n'usava el 72 % (290 MB/s) |

### 3.2 Equip de casa
Totes les proves s'han fet el 16/11/2026, amb l'equip de casa arrencat des del disc USB de classe i **amb les VM aturades**. Les eines són les mateixes que a classe (descarregades amb `apt-get download` i executades des d'una carpeta d'usuari).

| Prova | Eina i condicions | Resultat | Interpretació |
|---|---|---|---|
| **Memòria** | `memtester 4.6.0`, 3,9 GB bloquejats amb `mlock` (el límit de l'usuari no en permet 4), 1 passada | **18 de 18 proves `ok`, 0 errors**. Durada: 6 min 3 s | La RAM no té errors. Evidència: [`t2-memtester-casa.txt`](evidencies/t2-memtester-casa.txt) |
| **Disc USB (el de les VM)** | `fio 3.36`, fitxer de 2 GB a `/home` (ext4), `direct=1` (sense memòria cau), `libaio`, 20 s per prova | Seqüencial 1 MB: **401 MB/s de lectura, 392 MB/s d'escriptura** · Aleatori 4K QD32: **20,3k IOPS de lectura** (79 MB/s), 32,6k d'escriptura · Aleatori 4K QD1: 3.618 IOPS de lectura (latència mitjana **276 µs**), 8.657 d'escriptura | Prop del màxim pràctic d'USB 3.0 (5 Gbit/s ≈ 450 MB/s útils). El disc està al 97 % d'ús en totes les proves. Evidència: [`t2-fio-usb.txt`](evidencies/t2-fio-usb.txt) |
| **Disc NVMe intern** | `fio 3.36` **només lectura**: la partició de Windows es munta en lectura (`udisksctl mount -o ro`) per no modificar res. Com que el controlador `ntfs3` no respecta `direct=1`, cada prova llig un fitxer gran diferent que no s'havia llegit abans, i amb `/proc/diskstats` es comprova que les dades venen del disc | Seqüencial 1 MB: **972 MB/s** (3.890 MiB llegits realment del disc en 4 s) · Aleatori 4K: 10,5k IOPS amb latència mitjana **94 µs** (QD1) | **Són mínims, no el màxim del disc:** el controlador NTFS de Linux passa per la memòria cau i fa les peticions d'una en una (QD32 dona el mateix que QD1). Tot i això, el NVMe llig 2,4 vegades més ràpid que el disc USB i amb un terç de la latència. El valor de fàbrica (N/C, fitxa del fabricant) es comprovaria amb `winsat disk` des del Windows de casa. Evidència: [`t2-fio-nvme.txt`](evidencies/t2-fio-nvme.txt) |
| **Xarxa (enllaç)** | `/sys/class/net/eno1`, `ip -s link` | **1000 Mbit/s full duplex**, 0 errors i 0 paquets descartats | La NIC és de 2,5 Gbit/s però el router de casa és Gigabit |
| **Xarxa (latència)** | `ping -c100 -i0.2` al router `192.168.18.1` · `ping -c20` a `1.1.1.1` | Router: **0 % de pèrdua**, 0,55 ms de mitjana · Internet: 0 % de pèrdua, 7,96 ms | Xarxa estable |
| **Xarxa (Internet)** | `curl` descarregant la ISO del DVD de Debian 13.7 durant 12 s a `/dev/null` | **738 MB en 12 s = ~492 Mbit/s** | El límit és la connexió contractada, no la NIC. Evidència: [`t2-xarxa-casa.txt`](evidencies/t2-xarxa-casa.txt) |

### 3.3 Conclusió: es confirmen els colls de botella?

| Coll de botella previst | Classe | Casa |
|---|---|---|
| Disc USB de les VM | **Confirmat** (85-91 % d'ús amb càrrega real) | **Confirmat**: el mateix disc dona el mateix a l'altre equip (401 MB/s). El límit és el disc i la caixa USB 3.0, no l'ordinador |
| RAM | No (6,3 GB lliures amb 8 VM) | No (mateixa capacitat, 0 errors) |
| CPU | Descartat (87 % lliure amb 8 VM) | Descartat |
| Xarxa | No és de l'equip, és de l'eixida del centre | No |
| Espai al disc intern | No s'utilitza (és del centre) | **Nou:** NVMe al 87 %, cal alliberar espai abans de moure-hi les VM |

### 3.4 Conclusió sobre els colls de botella (equip de classe)
- **Disc: confirmat.** És l'únic recurs que arriba prop del 90 % d'ús, tant en la instal·lació com amb les 8 VM enceses ([Tasca 7](Tasca7.md)).
- **RAM: no és coll de botella** amb la càrrega actual. Amb les 8 VM, queden 6,3 GB disponibles i la swap no s'usa.
- **CPU: descartada.** 87 % lliure amb les 8 VM.
- **Xarxa: no és coll de botella del portàtil.** El límit és l'eixida del centre.
