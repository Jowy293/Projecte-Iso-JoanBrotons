# Tasca 6 · Emmagatzematge i RAID (part individual)

**RA:** ISO RA3 (a-h) · **Obligatori individual:** punt 2 (almenys 3 tipus de RAID)

> Evidència completa i sense retocar: [`evidencies/t6-raid.txt`](../evidencies/t6-raid.txt) · Script utilitzat: [`scripts/raid.sh`](../scripts/raid.sh)

## 1. Muntatge

| Element | Valor |
|---|---|
| Equip | VM `Ubuntu(Cliente)` · Ubuntu 26.04.1 LTS · `192.168.11.25` |
| Programari | `mdadm 4.5` (RAID per programari del nucli Linux) |
| Discos | 7 discos virtuals VDI de **512 MB** (`sdb`…`sdh`) al controlador SATA de la VM |
| Dades | Fitxers fictícis de 50 MB (`/dev/urandom`) amb el seu `sha256` per comprovar integritat |

Per què RAID per programari i no la "RAID" de VirtualBox: VirtualBox no ofereix RAID; cada disc virtual és un fitxer al mateix SSD de l'amfitrió. `mdadm` és el que s'utilitza en servidors Linux reals sense controladora RAID hardware, i permet provar fallades sense risc.

## 2. Arrays creats

| Array | Nivell | Discos | Capacitat bruta | Capacitat útil (`df`) | Tolera la fallada de |
|---|---|---|---|---|---|
| `/dev/md0` | RAID 0 (*striping*) | sdb, sdc | 1 GB | **986 MB** | **cap disc** |
| `/dev/md1` | RAID 1 (*mirroring*) | sdd, sde | 1 GB | **463 MB** | 1 disc |
| `/dev/md5` | RAID 5 (paritat distribuïda) | sdf, sdg, sdh | 1,5 GB | **986 MB** | 1 disc |

```text
md5 : active raid5 sdh[3] sdg[1] sdf[0]      1044480 blocks ... [3/3] [UUU]
md1 : active raid1 sde[1] sdd[0]             523264 blocks  ... [2/2] [UU]
md0 : active raid0 sdc[1] sdb[0]             1044480 blocks ... 512k chunks
```

Persistència: arrays a `/etc/mdadm/mdadm.conf` (`mdadm --detail --scan`), `update-initramfs -u` i muntatge a `/etc/fstab` per etiqueta amb `nofail` (si un array no arrenca, el sistema no es queda bloquejat a l'arrencada).

## 3. Verificació del funcionament (proves de fallada)

| Prova | Què s'ha fet | Resultat observat |
|---|---|---|
| RAID 1 – fallada | `mdadm /dev/md1 --fail /dev/sde` | Estat `[2/1] [U_]`, `sha256sum -c` → **OK** (dades íntegres amb un sol disc) |
| RAID 1 – reconstrucció | `--remove`, `--zero-superblock`, `--add` | Resincronització completa en **5 s** (`State : clean`, 2 dispositius actius) |
| RAID 5 – fallada | `mdadm /dev/md5 --fail /dev/sdg` | `State : clean, degraded`, `sha256sum -c` → **OK** (dades reconstruïdes amb la paritat) |
| RAID 5 – reconstrucció | `--remove`, `--add` | Reconstrucció en **3 s**, `State : clean`, 3 actius |
| RAID 0 – fallada | `mdadm /dev/md0 --fail /dev/sdc` | `mdadm: Cannot remove /dev/sdc from /dev/md0, array will be failed.` → no hi ha redundància: perdre un disc és perdre-ho tot |

Els temps de reconstrucció són tan curts perquè els discos són de 512 MB i són fitxers al mateix SSD. En un disc real de 4 TB la reconstrucció pot durar hores i durant eixe temps l'array és vulnerable.

### Sobre les velocitats mesurades
`dd ... oflag=direct` va donar 1,5–2,1 GB/s als tres arrays. **No són xifres representatives**: els 7 discos virtuals són fitxers al mateix SSD USB de l'amfitrió i VirtualBox fa servir la memòria cau de l'amfitrió. L'amfitrió real (Kingston A400 per USB 3.0) no passa de ~300 MB/s de lectura (vegeu Tasca 7). Per a comparar rendiments de RAID de veritat calen discos físics independents.

## 4. Què aporta cada tipus de RAID

| | RAID 0 | RAID 1 | RAID 5 |
|---|---|---|---|
| Idea | Reparteix els blocs entre discos | Còpia idèntica a cada disc | Reparteix dades + paritat (XOR) entre ≥3 discos |
| Espai útil | 100 % (N discos) | 50 % (1 disc) | (N-1)/N → 66 % amb 3 discos |
| Rendiment | Lectura i escriptura més ràpides | Lectura ràpida, escriptura igual que un disc | Lectura bona, escriptura penalitzada (càlcul de paritat) |
| Tolerància | Cap | 1 disc (o N-1) | 1 disc |
| Ús adequat a l'empresa | Dades temporals o reproduïbles (caché, *scratch*) | Sistema operatiu dels servidors, base de dades xicoteta | Carpetes compartides i còpies on importa la capacitat |

**Idea clau:** cap RAID és una còpia de seguretat. Si s'esborra un fitxer o hi ha un *ransomware*, el RAID replica l'error a tots els discos. Per això, a més del RAID, l'entorn té les còpies al TrueNAS (Tasca 5).

## 5. Limitacions
- Tots els discos són al mateix disc físic: una fallada de l'SSD de l'amfitrió afectaria tots els "discos" alhora. És una simulació per aprendre el comportament, no protecció real.
- No s'ha provat RAID 6/10 (no ho demanava l'activitat).
