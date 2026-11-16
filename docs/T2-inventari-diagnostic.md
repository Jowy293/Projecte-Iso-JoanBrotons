# Tasca 2 · Inventari de l'equip de classe i de casa, colls de botella i diagnòstic

**RA:** FDM RA1 a-h

## 1. Inventari

### 1.1 Equip de classe (dades reals)
Obtingut el 16/11/2026 amb `lscpu`, `free`, `lsblk`, `lsusb -t`, `lspci`, `/sys/class/dmi` i `/sys/class/thermal`. Eixida completa: [`evidencies/inventari-host-classe.txt`](../evidencies/inventari-host-classe.txt)

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

### 1.2 Equip de casa
> **N/C — a completar per l'alumne.** No he tingut accés al PC de casa. Les dades del README antic no tenien cap evidència al darrere i no s'han copiat. Per a obtindre-les, cal executar [`scripts/inventari-casa.ps1`](../scripts/inventari-casa.ps1) en PowerShell com a administrador. Genera `inventari-casa.txt` amb el model, la CPU, els mòduls de RAM, els discos (tipus i bus), la xarxa, el TPM i el Secure Boot, i a més executa `winsat` de disc, memòria i CPU. Després cal pujar el fitxer a `evidencies/` i omplir la taula.

| Component | Equip de casa |
|---|---|
| Model / placa | N/C |
| SO | N/C |
| CPU (nuclis/fils, virtualització) | N/C |
| RAM (mòduls, velocitat) | N/C |
| Discos (model, NVMe/SATA, bus) | N/C |
| Xarxa | N/C |
| TPM / Secure Boot | N/C |

## 2. Colls de botella

### 2.1 Equip de classe
| Recurs | Previsió | Comprovació | Conclusió |
|---|---|---|---|
| **Disc** | Les VM viuen en un SSD SATA connectat per USB 3.0. El límit teòric és ~450 MB/s (5 Gbit/s menys la sobrecàrrega de UAS) i, en la pràctica, el que done l'A400 | Prova de disc (§3) + mesura durant la instal·lació del Windows Server: **~290 MB/s de lectura sostinguda amb el disc al 85-90 % d'utilització** ([`t7-carrega-instalacio-winserver.txt`](../evidencies/t7-carrega-instalacio-winserver.txt)) | **CONFIRMAT, és el coll de botella principal.** Quan una VM fa E/S intensiva (instal·lació, actualitzacions), la resta van lentes |
| RAM | 18,5 GB per a totes les VM + ~6 GB de l'amfitrió (navegador, editor) | Amb 5 VM enceses: 19,8 GB usats, 11,5 GB disponibles, swap 0 | No és coll de botella fins a ~8 VM. A partir d'ahí l'amfitrió es queda sense memòria cau i augmenta l'E/S de disc |
| CPU | 18 fils sobrats per a VM de 1-2 vCPU | Amb 5-6 VM: **86-91 % de CPU lliure** | **DESCARTAT** |
| Tèrmic | Portàtil prim amb càrrega sostinguda | 68 °C amb 5 VM i una instal·lació en curs, sense *throttling* observat | No observat amb aquesta càrrega (al README antic es parlava de 92 °C sense cap mesura) |
| Xarxa | Gigabit Ethernet | La WAN de les VM va en pont: el que limita és la xarxa de l'aula, no la NIC | No és coll de botella per a l'entorn |

**Solucions aplicades / proposades (ajustades al maquinari disponible):**
1. Encendre les VM per torns i **guardar l'estat** de les que no s'utilitzen. Una VM guardada no consumeix ni RAM ni CPU.
2. No instal·lar ni actualitzar dues VM alhora.
3. Ajustar la RAM de cada VM al que consumeix de veritat (Tasca 7, optimització 1).
4. Millora de maquinari recomanada: treballar en un **SSD NVMe en caixa USB 3.2 Gen 2 (10 Gbit/s)** o en un SSD intern. És el que donaria més rendiment per euro invertit, molt per davant de més RAM o més CPU.

### 2.2 Equip de casa
> N/C fins que hi haja l'inventari. Guia d'anàlisi: si té ≥16 GB de RAM i un SSD NVMe intern, el coll de botella previst serà la RAM, si s'encenen totes les VM, i no el disc. Si té HDD, el disc serà molt pitjor que a classe.

## 3. Proves de diagnòstic a l'equip de classe (Apte+)

Vegeu els resultats a [`evidencies/t2-diagnostic-classe.txt`](../evidencies/t2-diagnostic-classe.txt) i el resum de sota.
