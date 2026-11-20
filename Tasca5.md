# Tasca 5 · Instal·lació i comunicacions

**Alumne:** Joan Brotons Vidal · Posició 11 · **RA:** ISO RA1 d-h · FDM RA1 b-d

| Què demana l'enunciat (individual) | On està |
|---|---|
| **Obligatori:** configurar al meu entorn de proves els mateixos sistemes que el grup: servidors de comunicacions (MikroTik, OPNsense, Debian amb nftables), TrueNAS, Proxmox, Windows Server 2025, servidor d'infraestructura GNU/Linux i clients Windows 11 i GNU/Linux, cadascun amb les tasques de l'enunciat (usuari d'administració, xarxa, Internet per a la LAN, còpia al servidor de còpies, errada i recuperació…) | apartats 1 a 6 |
| Per a cada sistema: requisits, llicència i origen/integritat de la ISO; firmware i arrencada; versió; actualització i via de recuperació; una incidència d'instal·lació o arrencada real (símptoma, hipòtesi, comprovació, solució i retorn); una connexió permesa i una de bloquejada amb el registre | Dins de cada apartat |
| **Apte+:** implementar un sistema per a fer còpies de la configuració dels servidors crítics de l'entorn | apartat 2 (TrueNAS): còpies manuals i còpies automàtiques (2.4) |
| **Preguntes de l'enunciat** i justificació de firmware, arrencada, particionat i sistema de fitxers | Dins de l'apartat de cada sistema: firmware i disc a la taula de cada equip · Proxmox 3.6 a 3.9 · Windows Server 4.2 i 4.4 |

---

## 1. Servidors de comunicacions: OPNsense, MikroTik i Debian + nftables

### 1.0 Decisió de disseny: una sola LAN, tres passarel·les, cap DHCP a la LAN

Els tres servidors de comunicacions comparteixen la mateixa xarxa interna `redjoan11` (192.168.11.0/24):

| Equip | LAN (estàtica) | WAN | Rol |
|---|---|---|---|
| OPNsense 26.7 | `192.168.11.1/24` | DHCP de l'aula (`172.16.222.x`, adaptador pont) | **Passarel·la per defecte** de tots els equips |
| MikroTik RouterOS 7.24.5 | `192.168.11.2/24` | DHCP de l'aula | Passarel·la alternativa (contingència) |
| Debian 13 + nftables | `192.168.11.3/24` | DHCP de l'aula | Passarel·la alternativa |

- **Només les WAN dels servidors de comunicacions van per DHCP.** Tota la resta d'equips té IP manual (vegeu [Tasca 4](Tasca4.md)).
- **Cap servidor fa DHCP a la LAN.** Al principi el MikroTik repartia el rang `.5-.55`. Això provocava que el TrueNAS acabara a la `.55` i que el **propi OPNsense** agafara la `.50` a la seua LAN, amb la ruta per defecte cap al MikroTik. Amb tres passarel·les a la mateixa LAN, si hi ha més d'un DHCP, cada client acaba amb una passarel·la diferent a l'atzar.
- Per a provar el MikroTik o el Debian, el client canvia la passarel·la (`ip route replace default via 192.168.11.2`). Així es fa a les proves de sota.
- **Qualsevol dels tres dona Internet.** Si només està encés un servidor de comunicacions, n'hi ha prou amb posar la seua IP com a passarel·la al client i al servidor. Prova feta canviant la passarel·la de l'Ubuntu i del Windows Server a la `.1`, la `.2` i la `.3`: amb les tres hi ha connexió a Internet (TCP 443 a `www.gva.es` i HTTP a `deb.debian.org`), i el primer salt és sempre la passarel·la triada. El ping cap a fora no respon ni des del mateix Debian, perquè la xarxa de l'aula bloqueja l'ICMP cap a Internet. Evidència: [`evidencies/t5-passarelles-internet.txt`](evidencies/t5-passarelles-internet.txt)

![Windows Server eixint a Internet per les tres passarel·les](evidencies/captures/t5-ws-05-passarelles-internet.png)

### 1.1 Comprovacions comunes abans d'instal·lar

| Sistema | ISO | SHA-256 (calculat a l'amfitrió) | Arquitectura / requisits |
|---|---|---|---|
| OPNsense | `OPNsense.iso` | `1efd5dc9…8d5dcd`* | amd64, 1 vCPU, ≥2 GB RAM (s'han assignat 3 GB), 25 GB |
| MikroTik | `mikrotik-7.24.5.iso` | `4bff16b8…aec02` | x86_64, 512 MB, 2 GB disc |
| Debian | `debian-13.1.0-amd64-netinst.iso` | `658b28e2…568b3` | amd64, 2 GB, 20 GB |

Llistat complet de hash: [`evidencies/iso-sha256.txt`](evidencies/iso-sha256.txt). Com es comprova: s'ha de comparar el hash calculat amb el que publica el fabricant (`SHA256SUMS` de Debian, `.sha256` d'OPNsense, `CHECKSUMS` de MikroTik a la pàgina de descàrregues).
\* Valor complet a l'evidència.

### 1.2 OPNsense (`192.168.11.1`)

| Ítem | Configuració |
|---|---|
| Versió | `OPNsense 26.7 (amd64)` (`opnsense-version`) |
| Firmware, arrencada i disc | BIOS · arrencada: disc (després de la instal·lació, sense ISO al lector) · GPT: `efi` 260 MB, `freebsd-boot` 512 KB, arrel 25 GB · **UFS** amb *soft-updates*. **Per què:** És el que proposa l'instal·lador. Un tallafocs només guarda configuració i registres: no necessita les funcions de ZFS (instantànies, RAID) i UFS gasta menys RAM |
| Hostname | `opnsense11` |
| Usuari d'administració | `root` (reset des de la consola, opció 3). Accés web `https://192.168.11.1` i SSH només des de la LAN |
| WAN `em0` | DHCP (pont `eno1`) → `172.16.222.184/24`, gw `172.16.222.1` |
| LAN `em1` | Estàtica `192.168.11.1/24`, sense gateway |
| NAT | *Outbound* automàtic: `nat on em0 from (em1:network) -> (em0:0)` |
| DHCP | **Desactivat** |
| Regles LAN | 1) `block` TCP/23 amb *log* (prova) · 2) `pass` LAN → any amb *log* |

**Problemes trobats i resolts:**
1. La LAN tenia la `.50` encara que el `config.xml` deia `.1`: hi havia un `dhclient` llançat per un procés `daemon -r` sobre `em1`, i ho re-aplicava a partir del *lease* guardat a `/var/db/dhclient.leases.em1`. Solució: matar el `daemon`, esborrar el *lease*, reassignar la IP des de la consola (opció 2) i reiniciar per comprovar que es manté.
2. La ruta per defecte anava pel MikroTik (`192.168.11.2`), també heretada del DHCP. Després de la correcció: `default 172.16.222.1 UGS em0`.

Extracte de la configuració (sense claus ni hash): [`configs/opnsense-extracte.xml`](configs/opnsense-extracte.xml)

### 1.3 MikroTik (`192.168.11.2`)

| Ítem | Configuració |
|---|---|
| Versió | RouterOS **7.24.5 (stable)**, x86_64 (`/system resource print`) |
| Firmware, arrencada i disc | BIOS · arrencada: disc · Imatge de disc de RouterOS (2 GB) · Propi de RouterOS. **Per què:** RouterOS s'instal·la com una imatge tancada; no es pot triar |
| Identitat | `MikroTik-11` |
| Usuaris | `administrador11` (grup *full*). `admin` **desactivat**. ~~`backup`~~ (usuari de còpies amb clau SSH, **eliminat** en passar a còpies manuals; abans: grup `copies`: només `ssh,read,sensitive,test,ftp`, sense `write`, només des de `192.168.11.5`, amb clau SSH) |
| WAN `ether1` | Client DHCP → `172.16.222.213/24` |
| LAN `ether2` | `192.168.11.2/24` |
| NAT | `srcnat out-interface-list=WAN action=masquerade` (**no existia: per això no hi havia Internet a través del MikroTik**) |
| DHCP | Servidor `dhcp1` **desactivat**; pool reduït a `.200-.220` per si cal activar-lo en contingència |
| Firewall | input: establertes, ICMP, LAN, SSH/Winbox només des de 172.16.222.0/24, resta WAN *drop+log* · forward: establertes, **Telnet LAN→fora *drop+log* (`MK-BLOQ-TELNET`)**, LAN→WAN *accept*, WAN→LAN *drop+log* |

Configuració exportada (sense dades sensibles): [`configs/mikrotik-export.rsc`](configs/mikrotik-export.rsc)

**Limitació detectada:** és la imatge x86 sense llicència (`ROUTER HAS NO SOFTWARE KEY`, mode de prova de 24 h). Per a un ús continu s'hauria d'utilitzar la imatge **CHR** (llicència gratuïta *free*, limitada a 1 Mbps per interfície) o comprar una llicència de nivell 4.

### 1.4 Debian 13 + nftables (`192.168.11.3`)

| Ítem | Configuració |
|---|---|
| Versió | Debian GNU/Linux 13 (trixie), nucli 6.12.113 |
| Firmware, arrencada i disc | BIOS · arrencada: **Disc primer**, sense menú F12 (Tasca 7) · MBR: arrel 18,9 GB + partició estesa amb *swap* 1,1 GB · **ext4**. **Per què:** Sistema de fitxers estàndard de Debian, estable i amb diari. Per a un servidor de comunicacions no cal res més |
| Hostname | `deb-comms11` |
| Usuaris | `administrador11` (afegit al grup `sudo`; abans no tenia permisos) i `root` |
| WAN `enp0s3` | DHCP per `ifupdown` (`/etc/network/interfaces`) |
| LAN `enp0s8` | `192.168.11.3/24` estàtica |
| Encaminament | `net.ipv4.ip_forward=1` persistent a `/etc/sysctl.d/99-router.conf` |
| Tallafocs | `/etc/nftables.conf` → [`configs/debian-nftables.conf`](configs/debian-nftables.conf) (input i forward amb política `drop`, NAT `masquerade`, bloqueig de Telnet amb *log* `DEB-BLOQ-TELNET`) |
| Serveis | Arrenca en mode text (`multi-user.target`): s'han desactivat l'escriptori GNOME (`gdm`), `cups`, `avahi` i `ModemManager`, que no calen en un tallafocs. Arrencada de 1 min 6 s a 4,9 s i RAM de 639 a 276 MB ([Tasca 7, apartat 4.2](Tasca7.md)) |
| SSH | `openssh-server` instal·lat (no ho estava) |

**Problemes trobats i resolts:**
1. `nftables.service` estava **inactive (dead)**: el fitxer tenia el NAT però no s'aplicava mai → la LAN no eixia per la `.3`. Solució: `systemctl enable --now nftables`.
2. La WAN tenia **dues IP** (`.194` i `.195`) perquè la gestionaven alhora `ifupdown` i NetworkManager. Solució: `/etc/NetworkManager/conf.d/10-ifupdown-gestiona.conf` amb `unmanaged-devices` per a `enp0s3` i `enp0s8`.
3. NTP (UDP/123) està bloquejat a la xarxa de l'aula i el rellotge quedava endarrerit (les VM es reprenen des d'estat guardat). Això feia fallar `apt` ("signatura no vàlida encara"). Solució: un *timer* de systemd que agafa l'hora de la capçalera `Date` d'una resposta web i la posa amb `date -s`.

### 1.5 Connexió permesa i connexió bloquejada (amb registre)

Client: Ubuntu `192.168.11.25`. S'ha canviat la passarel·la a `.1`, `.2` i `.3` successivament.
Evidència: [`evidencies/t5-proves-firewall-client.txt`](evidencies/t5-proves-firewall-client.txt) i [`evidencies/t5-logs-firewalls.txt`](evidencies/t5-logs-firewalls.txt)

| Passarel·la | tracepath | Permesa: HTTP a deb.debian.org:80 | Bloquejada: TCP 1.1.1.1:23 |
|---|---|---|---|
| `.1` OPNsense | 192.168.11.1 → 172.16.222.1 → 172.18.22.1 | OK 0,51 s | sense resposta |
| `.2` MikroTik | 192.168.11.2 → 172.16.222.1 → … | OK 0,45 s | sense resposta |
| `.3` Debian | 192.168.11.3 → 172.16.222.1 → … | OK 0,47 s | sense resposta |

**Interpretació dels registres:**

- **OPNsense** (`/var/log/filter/latest.log`):
  ```
  ... 949c6a24-...,em1,match,pass,in,4,...,tcp,60,192.168.11.25,199.232.34.132,34914,80,0,S,...
  ... 5cabc572-...,em1,match,block,in,4,...,tcp,60,192.168.11.25,1.1.1.1,33056,23,0,S,...
  ```
  Camps: UUID de la regla que ha fet *match*, interfície `em1` (LAN), acció (`pass`/`block`), sentit `in`, IPv4, protocol TCP, origen, destinació, port origen, **port destí** (80/23) i *flag* `S` (SYN, intent de connexió nova). El bloqueig es repeteix 5 vegades amb el mateix port origen 33056: són les **retransmissions del SYN** del client, que no rep resposta.
- **MikroTik** (`/log print`):
  `MK-BLOQ-TELNET forward: in:ether2 out:ether1, connection-state:new src-mac 08:00:27:C2:F7:C9, proto TCP (SYN), 192.168.11.25:54500->1.1.1.1:23`. Inclou la MAC del client (la de l'Ubuntu), i els comptadors de la regla 8 (`10 paquets, 600 bytes`) confirmen que ha actuat.
- **Debian** (`journalctl -k`):
  `DEB-BLOQ-TELNET IN=enp0s8 OUT=enp0s3 ... SRC=192.168.11.25 DST=1.1.1.1 ... PROTO=TCP SPT=54514 DPT=23 ... SYN`. `IN/OUT` indica que el paquet anava a ser reenviat (cadena *forward*) de la LAN a la WAN.

Nota: el `ping 8.8.8.8` **no funciona des de cap equip de l'aula** (ni des de l'amfitrió): la xarxa del centre filtra l'ICMP cap a Internet. Per això la connectivitat externa es prova amb HTTP.

### 1.6 Còpia de la configuració al servidor de còpies

Les còpies les fa **l'administrador a mà**, sense tasques programades: entra a cada equip amb el seu usuari, n'exporta la configuració i la deixa a la carpeta compartida del TrueNAS. Els passos estan a l'[apartat 2](#2-truenas-servidor-de-còpies-192168115).

| Equip | Què es copia | Fitxer al TrueNAS | Mida |
|---|---|---|---|
| OPNsense | `/conf/config.xml` (tota la configuració en un fitxer) | `opnsense/config-opnsense11-20261117-0925.xml` | 37 KB |
| MikroTik | `/export show-sensitive` (text, reimportable) | `mikrotik/mikrotik11-20261117-0925.rsc` | 2,2 KB |
| Debian | `tar` de `/etc/nftables.conf`, `interfaces`, `sysctl.d`, `sshd_config`, `hosts`, NM i el *timer* d'hora | `debian-comms/deb-comms11-etc-20261117-0925.tar.gz` | 3,7 KB |

**Què NO es copia i per què:** la imatge sencera del disc (OPNsense 25 GB, Debian 20 GB) no cap al pool de 5 GB i no cal: reinstal·lar des de la ISO verificada + restaurar la configuració és més ràpid i ocupa uns quants KB.

### 1.7 Errada controlada i recuperació

Durant cada prova, el client Ubuntu feia un `wget` cada segon per la passarel·la provada i registra els canvis d'estat.

| Equip | Errada provocada | Recuperació | Caiguda observada pel client | Evidència |
|---|---|---|---|---|
| Debian | `rm /etc/nftables.conf; nft flush ruleset` (es perd el NAT) | Des del TrueNAS: `cat còpia.tar.gz \| ssh root@.3 "tar xzf - -C / etc/nftables.conf && systemctl restart nftables"` | **13 s** (10:40:33 → 10:40:46, 12 s eren d'espera) | [`t5-fallada-debian.txt`](evidencies/t5-fallada-debian.txt) |
| OPNsense | S'esborra la regla *Default allow LAN to any* i es recarrega el filtre | Es restaura `config.xml` des del TrueNAS + `configctl filter reload` | **13 s** (10:52:59 → 10:53:12) | [`t5-fallada-opnsense.txt`](evidencies/t5-fallada-opnsense.txt) |
| MikroTik | **Reset de fàbrica** `/system reset-configuration no-defaults=yes` | Consola: IP temporal → `/tool fetch mode=sftp` de la còpia del TrueNAS → `/ip address remove [find]; /import restore.rsc` → tornar a crear els usuaris | **1 min 51 s** (10:49:45 → 10:51:36, inclou el reinici) | [`t5-fallada-mikrotik.txt`](evidencies/t5-fallada-mikrotik.txt) |

**Lliçons apreses (reals, eixides de les proves):**
- `/export` del MikroTik **no inclou els usuaris ni les claus SSH**: després d'importar cal recrear `administrador11`. Millora: guardar també un `/system backup` binari (inclou usuaris) a més de l'export de text.
- Després del reset, el MikroTik genera una **clau de host SSH nova** i la primera còpia posterior va fallar ("REMOTE HOST IDENTIFICATION HAS CHANGED"). És el comportament segur; es resol amb `ssh-keygen -R 192.168.11.2` un cop comprovat que el canvi és legítim.
- Al Debian i a l'OPNsense, la recuperació en si dura menys de 2 s; la major part de la caiguda és el temps a detectar el problema.

## 2. TrueNAS: servidor de còpies (192.168.11.5)

### 2.1 Sistema

| Ítem | Valor |
|---|---|
| Versió | `TrueNAS-27.0.0-RC.1` (`midclt call system.version`). ISO `TrueNAS-27.0.0-RC.1.iso`, SHA-256 `515a0252…498e` |
| Firmware, arrencada i disc | BIOS · arrencada: disc · Disc 1 (18 GB): `boot-pool` · Disc 2 (5 GB): pool `Copias` · **ZFS**. **Per què:** TrueNAS només funciona amb ZFS. Té sumes de verificació (detecta dades corruptes), compressió LZ4 i quotes per dataset. Les còpies van en un **disc separat** del sistema, com demana l'enunciat |
| VM | 1 vCPU, 2 GB RAM, disc de sistema 18 GB (`boot-pool`) + **disc addicional de 5 GB** (`sdb`) per a les còpies |
| Hostname | `truenas11` · zona horària `Europe/Madrid` |
| Xarxa | `enp0s3` **estàtica** `192.168.11.5/24`, gw `192.168.11.1` |
| Usuaris | `truenas_admin` (administrador, accés web i SSH) · `backup_user` (propietari de les còpies, home `/mnt/Copias/backups`) |
| Serveis | SSH amb contrasenya · SMB (recurs `backups`) · **FTP desactivat** (anava en clar i no feia falta) |

> **Requisit oficial:** TrueNAS recomana ≥8 GB de RAM per a ZFS. Aquí té 2 GB perquè el pool és de 5 GB i és un laboratori: funciona, però no és una configuració de producció.

**Problema trobat:** el TrueNAS estava en **DHCP** i agafava la `.55`, l'última IP del pool del MikroTik (`.5-.55`). Al README antic s'havia escrit `.55` com si fos una IP fixa. Ara està en estàtica a la `.5` (`interface.update` + `interface.commit` amb *rollback* automàtic de 60 s per si es perdia l'accés).

### 2.2 Espai de còpies: què, com i on

Pool ZFS **`Copias`** sobre el disc addicional de 5 GB (no al disc del sistema: si el sistema del NAS es trenca, les còpies sobreviuen al seu propi disc).

```
NAME                         QUOTA   COMPRESS
Copias/backups                  4G   lz4      ← propietari backup_user, permisos 750
Copias/backups/opnsense       200M   lz4
Copias/backups/mikrotik       200M   lz4
Copias/backups/debian-comms   300M   lz4
Copias/backups/proxmox        300M   lz4
Copias/backups/winserver        1G   lz4
Copias/backups/win11          512M   lz4
Copias/backups/ubuntu         512M   lz4
Copias/backups/infra          300M   lz4
Copias/backups/historic       200M   lz4      ← còpies manuals antigues conservades
```

- **Un dataset per equip amb quota** (RA3 g): si un equip genera còpies descontrolades, només omple la seua quota i no bloqueja les còpies de la resta. Les quotes s'han posat amb `zfs set quota=` perquè l'API de TrueNAS 27 exigeix un mínim d'1 GB.
- **Compressió LZ4**: els fitxers de configuració són text i es comprimeixen molt.
- El dataset antic `copias_de_seguiridad` (nom amb errata, compartit per SMB i FTP) s'ha eliminat després de copiar-ne el contingut a `historic/`.

#### Com es fa cada còpia (manual)

Hi ha dues maneres de fer les còpies: **a mà** (aquesta taula), que val per a tots els equips, i **automàticament** per als servidors Linux (apartat 2.4). Les còpies manuals les fa l'administrador quan acaba un canvi, entrant amb usuari i contrasenya:

| Equip | Com es treu la configuració | On es deixa |
|---|---|---|
| OPNsense | Web `https://192.168.11.1` → *Sistema → Configuració → Còpies de seguretat → Descarregar configuració* (o per SSH: `scp root@192.168.11.1:/conf/config.xml .`) | `backups\opnsense\` |
| MikroTik | Per SSH o Winbox com a `administrador11`: `/export show-sensitive file=mikrotik11` i baixar el fitxer des de *Files* (o copiar el text de l'eixida) | `backups\mikrotik\` |
| Debian | `sudo tar czf deb-comms11-etc-DATA.tar.gz /etc/nftables.conf /etc/network/interfaces /etc/sysctl.d /etc/ssh/sshd_config /etc/hosts ...` i `scp` a `backup_user@192.168.11.5` (demana contrasenya) | `backups/debian-comms/` |
| Proxmox | Al pve1 (amb una n'hi ha prou, el clúster replica `/etc/pve`): `tar czf pve-cluster-config-DATA.tar.gz /etc/pve /etc/network/interfaces /etc/hosts ...` i `scp` a `backup_user@192.168.11.5` | `backups/proxmox/` |
| Windows Server i Windows 11 | A mà, en un PowerShell com a administrador: `ipconfig /all`, `route print`, `Get-LocalUser`, `Get-HotFix`, `netsh advfirewall export`, `secedit /export` i la llista de programari; es comprimeix amb `Compress-Archive` i es copia a la carpeta compartida | `backups\winserver\` i `backups\win11\` |
| Ubuntu | `sudo tar czf ubuntu-client11-DATA.tar.gz /etc/NetworkManager/system-connections /etc/netplan /etc/fstab ...` i `scp` a `backup_user@192.168.11.5` | `backups/ubuntu/` |
| Servidor d'infraestructura | `sudo tar czf infra11-config-DATA.tar.gz /etc/network/interfaces /etc/hosts /etc/ssh/sshd_config ...` i `scp` a `backup_user@192.168.11.5` | `backups/infra/` |

L'última ronda de còpies manuals es va comprovar amb el `sha256sum` del fitxer a l'equip i al TrueNAS, que coincideixen. Evidència: [`evidencies/t5-copies-manuals.txt`](evidencies/t5-copies-manuals.txt)

#### Com entrar a veure les còpies

| Des d'on | Com |
|---|---|
| **Windows 11** (o qualsevol Windows de la LAN) | Explorador → `\\192.168.11.5\backups` → usuari `backup_user`. Es veu una carpeta per equip amb els fitxers i la data de cada còpia |
| Ubuntu | *Fitxers* → *Altres ubicacions* → `smb://192.168.11.5/backups` (usuari `backup_user`) |
| Consola | `ssh backup_user@192.168.11.5` i `ls -l /mnt/Copias/backups/*` |
| Web del TrueNAS | `https://192.168.11.5` → *Datasets* → `Copias/backups`: mostra l'espai usat i la quota de cada carpeta |

![Carpeta compartida de còpies vista des del Windows 11](evidencies/captures/t5-copies-01-carpeta-compartida.png)

Al principi hi havia un sistema de còpies fet amb fitxers d'ordres propis i claus SSH sense restricció. Es va retirar i s'ha substituït per les eines del mateix TrueNAS (apartat 2.4).

### 2.3 Recuperació provada
Les tres recuperacions de l'[apartat 1.7](#1-servidors-de-comunicacions-opnsense-mikrotik-i-debian--nftables) s'han fet **a partir d'aquestes còpies**: el MikroTik es va descarregar la seua per SFTP (`/tool fetch mode=sftp ... user=backup_user`), i al Debian i a l'OPNsense el TrueNAS els va retornar el fitxer per SSH.

### 2.4 Còpies automatitzades: eina triada, per què i prova

L'objectiu és que la configuració dels servidors crítics es copie sola cada nit al TrueNAS, que se'n guarden diverses versions i que, si una còpia falla, l'administrador se n'assabente.

#### Opcions estudiades

| Opció | Com funciona | A favor | En contra |
|---|---|---|---|
| Fitxers d'ordres propis + `cron` + `scp` | Cada servidor (o el NAS) executa unes ordres programades que copien els fitxers | Molt flexible | S'ha de mantenir el codi a mà, no guarda versions, no avisa si falla i les claus solen tindre accés complet. És el que hi havia al principi i es va retirar |
| **Tasques Rsync del TrueNAS + instantànies periòdiques ZFS** ✅ | El NAS va a buscar (*PULL*) els fitxers de cada servidor per SSH a l'hora programada. Després, una instantània ZFS guarda la versió del dia | Ja està al NAS que tenim, es gestiona des de la web, mostra l'estat de cada tasca i avisa si falla. Les instantànies donen versions i no es poden modificar. Als servidors només cal `rsync`, que ja tenen | Només serveix per a equips amb SSH i `rsync` (Linux). Copia fitxers, no la imatge sencera del sistema |
| BorgBackup / restic | Programes de còpia amb deduplicació i xifratge que s'instal·len a cada servidor | Còpies xifrades i molt compactes, amb versions | S'ha d'instal·lar i programar a cada equip i no té interfície web. Al TrueNAS, restic només s'utilitza per a les còpies al núvol |
| Bacula / Bareos | Sistema empresarial amb director, servidor d'emmagatzematge i un agent a cada equip (també Windows) | Ho cobreix tot, amb catàleg i polítiques | Molt complex de muntar i pesat per a un NAS amb 2 GB de RAM |
| UrBackup | Servidor de còpies amb agents per a Windows i Linux; fa còpies de fitxers i d'imatges | Interfície web, també per a Windows | Necessita un servidor més (o una aplicació al TrueNAS) i un agent a cada equip, i més RAM de la que hi ha |
| Proxmox Backup Server | Còpies de les VM i contenidors de Proxmox | Ideal per a les VM del clúster | Només serveix per a VM i contenidors, i dins dels Proxmox no n'hi ha cap |

#### Per què s'han triat les tasques del TrueNAS

1. **No cal instal·lar res de nou:** el TrueNAS ja és el servidor de còpies i porta les tasques Rsync i les instantànies. Els servidors Debian i Proxmox ja tenen `rsync`.
2. **Es gestiona i es comprova des de la web:** a *Data Protection* es veu cada tasca, quan s'executarà i si l'última execució ha acabat bé o no. Si falla, el TrueNAS genera una alerta.
3. **Els servidors no poden tocar les còpies:** com que és el NAS qui va a buscar els fitxers (*PULL*), els servidors no tenen cap clau ni contrasenya del NAS. Si atacaren un servidor, no podrien esborrar les còpies.
4. **Versions:** cada nit es fa una instantània ZFS de totes les còpies i es conserva 14 dies. Les instantànies són de només lectura, de manera que, si es copia un fitxer trencat, la versió bona continua a la instantània del dia abans.
5. **La clau només serveix per a copiar:** als servidors la clau està limitada amb `rrsync -ro /etc`, que només deixa llegir `/etc` amb rsync, i només des de la IP del NAS.

#### Com s'ha configurat

| Pas | On | Detall |
|---|---|---|
| 1. Parell de claus | TrueNAS → *Credentials* → *Backup Credentials* → *SSH Keypairs* | Clau `copies-automatiques`, generada pel mateix TrueNAS |
| 2. Autoritzar la clau | Cada servidor, `/root/.ssh/authorized_keys` (al Proxmox, `/etc/pve/priv/authorized_keys`, que és el mateix per als tres nodes) | `from="192.168.11.5",restrict,command="/usr/bin/rrsync -ro /etc" ssh-rsa …`. `rrsync` ve amb el paquet `rsync` |
| 3. Connexions SSH | TrueNAS → *SSH Connections* | `ssh-debian-comms` (192.168.11.3), `ssh-proxmox` (192.168.11.17) i `ssh-infra` (192.168.11.30), amb la clau del pas 1 i la clau de host de cada servidor |
| 4. Tasques Rsync | TrueNAS → *Data Protection* → *Rsync Tasks* | Una per servidor: mode SSH, direcció **PULL**, origen `/` (és a dir, el `/etc` del servidor, per `rrsync`), destí `/mnt/Copias/backups/<equip>/auto`, usuari `backup_user`, **cada dia a les 02:00**. Opcions *archive*, *compress* i *delete* (la carpeta queda igual que el servidor; les versions antigues les guarden les instantànies). S'exclouen `shadow`, `gshadow` i les claus privades de host SSH |
| 5. Instantànies | TrueNAS → *Data Protection* → *Periodic Snapshot Tasks* | `Copias/backups` (recursiu), **cada dia a les 02:30**, es conserven **14 dies**, nom `auto-AAAA-MM-DD_HH-MM` |

Equips que cobreix: el **Debian de comunicacions**, el **clúster Proxmox** (des del pve1 es copia `/etc/pve`, que és la configuració de tot el clúster) i el **servidor d'infraestructura**. L'OPNsense, el MikroTik i els Windows continuen amb la còpia manual de l'apartat anterior perquè no tenen `rsync`.

#### Proves fetes

| Prova | Què s'ha fet | Resultat |
|---|---|---|
| Primera còpia | Executar les tres tasques des de la web | Correctes en ~1 s cadascuna: Debian 992 fitxers (5,9 MB), Proxmox 730 (2,2 MB, amb `corosync.conf` i `nodes/`), infraestructura 538 (1,7 MB). `shadow` no s'ha copiat |
| **Execució automàtica** | Programar la tasca de l'infra11 per a dos minuts després i no tocar res | La tasca s'executa sola a les **08:33:01** i acaba bé. Després es torna a deixar a les 02:00 |
| Seguretat de la clau | Des del TrueNAS, amb la clau de les còpies, intentar obrir una shell, escriure un fitxer al servidor i llegir `/root` | Les tres coses es rebutgen (`does not run rsync`, `read-only server`, `do not use ..`). Llegir `/etc/hostname` sí que funciona |
| **Versions i recuperació** | Fer una instantània, afegir una línia a `/etc/motd` de l'infra11, tornar a copiar i recuperar el fitxer bo des de la instantània (`.zfs/snapshot/auto-…/auto/motd`) | `diff` mostra la línia nova a la còpia actual i no a la instantània. Fitxer recuperat al servidor en **0,7 s** i idèntic a l'original |
| **Servidor caigut** | Posar en pausa la VM de l'infra11 i executar la seua tasca | La tasca falla (`rsync command returned 255`) i el TrueNAS mostra l'alerta **CRITICAL** *Rsync "PULL" task … failed*. En tornar a engegar el servidor, la còpia següent acaba bé |

**Problema trobat:** la primera execució contra l'infra11 fallava (`rsync command returned 12`). El servidor accepta la clau, però `rrsync` és un programa en Python i la instal·lació mínima de Debian no porta Python. Solució: instal·lar `python3` a l'infra11.

**Problema trobat:** en crear les tasques, el TrueNAS comprova que la carpeta remota existeix executant una orden que no és rsync, i `rrsync` la rebutja. S'ha desactivat aquesta comprovació a la tasca (*Validate Remote Path*). La restricció de la clau funciona com ha de funcionar.

Evidència: [`evidencies/t5-copies-automatiques.txt`](evidencies/t5-copies-automatiques.txt)

| | |
|---|---|
| ![Data Protection: tasques d'instantànies i Rsync](evidencies/captures/t5-auto-01-data-protection.png) | ![Les tres tasques Rsync](evidencies/captures/t5-auto-02-tasques-rsync.png) |
| *Data Protection*: instantànies diàries i les tres tasques Rsync completades | Tasques Rsync en mode PULL, a les 02:00, amb l'usuari `backup_user` |
| ![Clau i connexions SSH](evidencies/captures/t5-auto-03-credencials-ssh.png) | ![Instantànies de les còpies](evidencies/captures/t5-auto-04-instantanies.png) |
| Clau `copies-automatiques` i les tres connexions SSH | Instantània de cada carpeta de còpies |

#### Limitacions i millores

- **Les instantànies estan al mateix disc que les còpies.** Si es trenca el disc de 5 GB, es perd tot. La millora és replicar el pool a un altre equip (*Replication Tasks* del TrueNAS cap a un segon NAS) per a complir la regla 3-2-1 (3 còpies, 2 suports, 1 fora).
- **Només Linux.** Per a l'OPNsense es podria activar la seua còpia automàtica de la configuració, i per al Windows Server, *Windows Server Backup* programat cap a la carpeta compartida.
- **Només es copia `/etc`**, no la imatge del sistema. Per a aquests servidors és suficient perquè es reinstal·len en minuts, però per a servidors amb dades caldria afegir-ne les carpetes.

## 3. Proxmox VE: clúster de 3 nodes (192.168.11.17, .18 i .19)

> Dins dels Proxmox **no hi ha cap màquina virtual ni contenidor**: a l'entorn individual només es configuren els nodes, la xarxa, els usuaris d'administració i el clúster.

Evidències: [`evidencies/t5-proxmox-estat.txt`](evidencies/t5-proxmox-estat.txt) · [`evidencies/t5-proxmox-cluster.txt`](evidencies/t5-proxmox-cluster.txt) · [`evidencies/t5-proxmox-copia.txt`](evidencies/t5-proxmox-copia.txt)

### 3.1 Sistema

| Ítem | Valor |
|---|---|
| Versió | `pve-manager/9.2.2` (nucli 7.0.2-6-pve), base Debian 13 trixie |
| ISO | `proxmox-ve_9.2-1.iso` · SHA-256 `4e88fe41…f0395` **coincideix** amb `enterprise.proxmox.com/iso/SHA256SUMS` |
| Instal·lació | Instal·lador en mode text (*Terminal UI*): disc `ext4`, país Espanya, zona `Europe/Madrid`, teclat espanyol |
| Firmware, arrencada i disc | BIOS · arrencada: disc · GPT: BIOS boot, EFI 512 MB i LVM (`root` 13,8 GB ext4, `swap` 1,9 GB i `data` *thin-pool* 11,8 GB) · **ext4** + **LVM-thin**. **Per què:** Opció per defecte de l'instal·lador. El *thin-pool* permet discos de VM que només ocupen el que s'escriu i instantànies. ZFS necessitaria molta més RAM, i els nodes només en tenen 2 GB |

| Node | VM VirtualBox | Hostname | IP (`vmbr0`) | Recursos |
|---|---|---|---|---|
| 1 | `Proxmox` | `pve1.joan11.local` | `192.168.11.17/24` | 1 vCPU, 2 GB, 30 GB · VT-x imbricat |
| 2 | `Proxmox2` | `pve2.joan11.local` | `192.168.11.18/24` | 2 vCPU, 2 GB, 32 GB · VT-x imbricat |
| 3 | `Proxmox3` | `pve3.joan11.local` | `192.168.11.19/24` | 2 vCPU, 2 GB, 32 GB · VT-x imbricat |

Tots tres a la xarxa interna `redjoan11`, amb porta d'enllaç `192.168.11.1` (OPNsense) i els tres noms a `/etc/hosts` de cada node.

| | |
|---|---|
| ![Resum de la instal·lació del pve2](evidencies/captures/t5-pve2-01-resum-installacio.png) | ![Resum de la instal·lació del pve3](evidencies/captures/t5-pve3-01-resum-installacio.png) |
| Resum abans d'instal·lar el node 2 | Resum abans d'instal·lar el node 3 |

### 3.2 Usuaris d'administració

| Usuari | Realm | Permisos |
|---|---|---|
| `root@pam` | PAM | Superusuari (necessari per al clúster i la consola) |
| `administrador11@pam` | PAM | Rol `Administrator` sobre `/` (ACL). Usuari Linux creat amb `useradd` i afegit a Proxmox amb `pveum user add` |

Els usuaris de Proxmox es guarden a `/etc/pve/user.cfg`, que el clúster replica als tres nodes. Com que el realm és **PAM**, l'usuari Linux `administrador11` s'ha creat també al pve2 i al pve3 (`useradd`). L'instal·lador obliga a posar una contrasenya de root de 8 caràcters com a mínim; després s'ha canviat amb `chpasswd` perquè siga la mateixa als tres nodes.

Accés web: `https://192.168.11.17:8006` (o `.18`, `.19`: des de qualsevol node es gestiona tot el clúster).

### 3.3 Xarxa

```text
auto vmbr0
iface vmbr0 inet static
        address 192.168.11.17/24
        gateway 192.168.11.1        # abans 192.168.11.2 (MikroTik)
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
```

- `vmbr0` és el pont Linux on es connectarien les VM i contenidors. El pve2 i el pve3 tenen la mateixa configuració amb la seua IP (`.18` i `.19`).
- Canvis aplicats amb `ifreload -a`, sense reiniciar.

### 3.4 Repositoris i actualització

- Als tres nodes s'han desactivat `pve-enterprise` i `ceph` (sense subscripció donen error 401) i s'ha afegit `pve-no-subscription`. Els fitxers originals estan a `/root/repos-desactivats/`.
- `apt update` funciona, i hi ha **130 paquets actualitzables**. **No s'ha fet `dist-upgrade`**: els tres nodes tenen la mateixa versió (9.2.2), que és el que importa en un clúster.
- Problema trobat: `apt update` fallava amb "signatura no vàlida fins a …" perquè el rellotge anava endarrerit (NTP bloquejat a l'aula i VM represa des d'estat guardat). S'ha resolt posant l'hora a partir de la capçalera `Date` d'una resposta web (`date -s`).
- **Problema trobat en muntar el clúster:** el pve1 anava un dia endarrerit (represa des d'estat guardat) i el pve2 i el pve3 anaven **una hora avançats**: VirtualBox dona el rellotge de la placa en hora local i Linux el llegia com si fora UTC. En un clúster les hores dels nodes han de coincidir (corosync i els certificats en depenen). Solució als tres nodes: `timedatectl set-local-rtc 1` (el rellotge de la placa va en hora local), hora posada des de l'amfitrió i `hwclock --systohc`.

### 3.5 Clúster `clusterjoan11`

| Pas | Ordre | Resultat |
|---|---|---|
| 1. Crear el clúster al pve1 | `pvecm create clusterjoan11 --link0 192.168.11.17` | Genera la clau de corosync (`/etc/corosync/authkey`) i `/etc/pve/corosync.conf` |
| 2. Afegir el pve2 | Al pve2: `pvecm add 192.168.11.17 --link0 192.168.11.18` (demana la contrasenya de root del pve1 i confirmar la seua empremta X509) | `successfully added node 'pve2' to cluster`. El node rep un certificat nou signat per l'autoritat del clúster |
| 3. Afegir el pve3 | Al pve3: `pvecm add 192.168.11.17 --link0 192.168.11.19` | `successfully added node 'pve3' to cluster` |
| 4. Comprovació | `pvecm status` i `pvecm nodes` **a cadascun dels tres nodes** | `Nodes: 3`, `Expected votes: 3`, `Quorum: 2`, `Quorate: Yes`. Els tres nodes en línia |

| | |
|---|---|
| ![Clúster vist des del pve2](evidencies/captures/t5-pve-01-cluster-pve2.png) | ![Clúster vist des del pve3](evidencies/captures/t5-pve-02-cluster-pve3.png) |
| `pvecm status` al pve2 | `pvecm status` al pve3 |

**Per què 3 nodes:** cada node té un vot i el clúster necessita la majoria (**quòrum = 2**) per a funcionar. Amb 3 nodes, si en cau un, els altres dos continuen tenint quòrum. Amb només 2, la caiguda d'un deixaria l'altre sense quòrum i bloquejaria `/etc/pve`.

**Limitació de l'entorn:** la xarxa del clúster (corosync, `link0`) va per la mateixa LAN que els usuaris. En una instal·lació real aniria per una xarxa separada perquè el trànsit dels usuaris no afecte la comunicació entre nodes.

### 3.6 Avantatges i inconvenients de la virtualització de servidors

> **Pregunta de l'enunciat:** *Indica les avantatges i inconvenients de la virtualització de servidors.*

| Avantatges | Inconvenients |
|---|---|
| **Consolidació:** diversos servidors en un mateix maquinari, amb menys consum, espai i cost | **Punt únic de fallada:** si el host cau, cauen totes les seues VM. Cal clúster i alta disponibilitat per a evitar-ho |
| **Instantànies** abans d'un canvi: si una actualització va malament, es torna enrere en segons (ho he fet amb el Windows 11, apartat 5.4) | **Rendiment compartit:** les VM competeixen per la RAM i el disc. Al meu entorn el disc és el coll de botella (Tasca 7) |
| **Còpia i restauració de la VM sencera** i trasllat a un altre host | **Complexitat:** cal saber administrar l'hipervisor, la xarxa virtual i l'emmagatzematge |
| **Migració** entre nodes d'un clúster per a fer manteniment sense aturar el servei | **Llicències:** Windows Server es llicencia per nuclis del host físic, no per VM |
| Crear un servidor nou és qüestió de minuts, sense comprar maquinari | Alguns dispositius (llicències lligades a maquinari, dongles USB) són difícils de virtualitzar |

### 3.7 Diferència entre contenidors i màquines virtuals. Quan utilitzar uns o altres?

> **Pregunta de l'enunciat:** *Investigar la diferència entre contenidors i màquines virtuals. Quan hem d'utilitzar uns o altres? Justifica la resposta.*

| | Contenidor (LXC a Proxmox) | Màquina virtual (KVM a Proxmox) |
|---|---|---|
| Nucli del sistema | **Comparteix el nucli del host** | **Té el seu propi nucli** sobre maquinari virtual |
| Sistemes que pot executar | Només Linux | Qualsevol: Windows, BSD, Linux… |
| Recursos | Molt pocs: centenars de MB de disc i RAM | Més: cal RAM i disc per a tot un sistema operatiu |
| Arrencada | Segons | Desenes de segons o minuts |
| Aïllament i seguretat | Menor: un error greu del nucli afecta tots els contenidors | Major: cada VM està aïllada per l'hipervisor |

**Quan utilitzar-los a la nostra empresa:**
- **Contenidors** per a serveis Linux senzills i lleugers: un servidor web intern, el monitoratge o una base de dades petita. Aprofiten millor la RAM, que és justament el recurs limitat.
- **Màquines virtuals** quan cal un altre sistema operatiu o més aïllament: el **Windows Server** (controlador de domini), un **tallafocs virtual** (OPNsense és FreeBSD) o qualsevol servei exposat a Internet.

### 3.8 Migració d'un contenidor i d'una màquina virtual entre nodes. Temps, espai i millores

> **Pregunta de l'enunciat:** *Realitza una migració de un contenidor i d'una màquina virtual d'un node a altre. Indica el temps que ha tardat, l'espai en disc que ocupa el contenidor i la màquina virtual. Es pot millorar?*

Amb el clúster, els tres nodes es gestionen des de la web de qualsevol d'ells (**gestió conjunta**). La **migració** mou una VM o un contenidor d'un node a un altre: en calent si el disc està en un emmagatzematge compartit, i copiant el disc si no ho està. L'**alta disponibilitat (HA)** torna a engegar automàticament una VM en un altre node quan el seu cau, i necessita quòrum i emmagatzematge compartit (NFS o iSCSI al TrueNAS, o Ceph).

> **No executat:** per decisió de l'entorn individual, dins dels nodes Proxmox no hi ha cap màquina ni contenidor (els nodes només tenen 2 GB de RAM cadascun). Es respon a partir del clúster muntat (apartat 3.5).

**Com es faria:** des de la web del clúster (*clic dret → Migrar*) o amb `pct migrate <id> pve2` (contenidor) i `qm migrate <id> pve2` (VM), cronometrant l'ordre i mirant l'espai amb `pvesm list local-lvm`.

**De què depèn el temps:** els nodes no tenen emmagatzematge compartit, així que la migració ha de **copiar el disc sencer** per la xarxa. Un contenidor Debian ocupa uns centenars de MB i una VM Linux mínima uns quants GB, de manera que **el contenidor migraria molt més ràpid**. A més, un contenidor no es pot migrar en calent: s'atura, es copia i es torna a engegar (`--restart`). Una VM sí que es pot migrar encesa, perquè també se'n copia la memòria.

**Es pot millorar?** Sí:
- **Emmagatzematge compartit** (NFS o iSCSI al TrueNAS, o Ceph): el disc no es mou, només la memòria. La migració passa de minuts a segons.
- **Xarxa dedicada i més ràpida** per a la migració (10 Gbit/s, separada de la dels usuaris).
- **Discos *thin*** (com el `local-lvm` que ja tenen els nodes): només es copia l'espai ocupat, no la mida total del disc.

### 3.9 Còpia del clúster al TrueNAS: què té sentit guardar i què no

> **Pregunta de l'enunciat:** *Guardar còpia dels principals fitxers, configuracions i/o imatge del clúster al servidor corresponent. Què té sentit guardar i què no?*

Còpia manual (apartat 2). Després de crear el clúster s'ha tornat a fer: `proxmox/pve-cluster-config-20261117-0925.tar.gz` (**21,3 KB**, abans 13,8 KB), que ja conté `corosync.conf`, `.members` i les carpetes dels tres nodes (`nodes/pve1`, `pve2`, `pve3`):

| Té sentit guardar | Per què |
|---|---|
| `/etc/pve/` (`corosync.conf`, `user.cfg`, `storage.cfg`, configuració dels nodes, tallafocs i certificats) | És tota la configuració del clúster. El clúster la replica als tres nodes, així que n'hi ha prou amb copiar-la d'un |
| `/etc/network/interfaces`, `/etc/hosts`, `/etc/hostname` i repositoris | Identitat i xarxa de cada node, per a reinstal·lar-lo igual |
| Les **VM i contenidors** (quan n'hi haja), amb `vzdump` cap a un emmagatzematge separat | És on estan les dades i els serveis de l'empresa |

| No té sentit guardar | Per què |
|---|---|
| El sistema operatiu dels nodes | Es reinstal·la des de la ISO en uns 10 minuts i s'hi aplica la configuració |
| Els discos de les VM copiats amb un `tar` | Una VM encesa canvia mentre es copia i la còpia quedaria inconsistent. Per a això està `vzdump` |
| Còpies al mateix disc dels nodes | Si falla el node, es perd la còpia. Han d'anar a un altre equip (el TrueNAS) |

**Compte:** la còpia conté claus privades del clúster (`priv/`): només la pot llegir `backup_user` (permisos 750 al dataset).

## 4. Windows Server 2025: controlador de domini joan11.local (192.168.11.10)

> Per indicació del professor, el Windows Server, que a l'arquitectura de referència va dins del clúster Proxmox, s'ha instal·lat **com a VM de VirtualBox independent** per falta de recursos per a la virtualització imbricada.

### 4.1 Instal·lació

| Ítem | Valor |
|---|---|
| ISO | `WinServer.iso` → *Windows Server 2025 Standard Evaluation (experiència d'escriptori)*, build **10.0.26100.32230**, es-ES (detectat amb `VBoxManage unattended detect`) |
| Requisits oficials | CPU x64 1,4 GHz amb SLAT, 512 MB RAM (2 GB amb escriptori), 32 GB de disc, TPM 2.0 i UEFI/Secure Boot **recomanats** però no obligatoris (a diferència de Windows 11) |
| Recursos assignats | 2 vCPU, 3 GB RAM, disc de 50 GB (marcat SSD, amb TRIM), BIOS |
| Firmware, arrencada i disc | **BIOS (legacy)** · arrencada: disc · **MBR**, una partició `C:` de 50 GB · **NTFS**. **Per què:** La instal·lació amb UEFI es quedava bloquejada al 18 % (incidència de l'apartat 4.1) i es va instal·lar amb BIOS. Windows Server **recomana** TPM i UEFI però no els exigeix |
| Llicència | Avaluació de 180 dies (no necessita clau) |
| Nom d'equip | `DC-JOAN11` |
| Usuari d'administració | `administrador11` (administrador local; en promocionar a DC passa a ser administrador del domini). `Administrador` integrat desactivat per Windows |

#### Incidència d'instal·lació real (punt 5 de la tasca): símptoma → hipòtesi → comprovació → solució

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

### 4.2 Què és un domini? Avantatges de centralitzar la gestió i què aporta a la nostra empresa

> **Pregunta de l'enunciat:** *Què és un domini? Quina és la utilitat (avantatges) de centralitzar la gestió del nostre sistema a nivell administratiu mitjançant un domini? Explica què aporta a la nostra empresa.*

Un **domini** (Active Directory a Windows Server) és una **base de dades centralitzada** amb tots els usuaris, grups, equips i polítiques de l'organització, guardada al **controlador de domini**. Els equips units al domini li deleguen l'autenticació: cada persona té **un sol compte** que li serveix a tots els equips i recursos de l'empresa.

**Avantatges de centralitzar la gestió amb un domini:**

| Sense domini (grup de treball) | Amb domini `joan11.local` |
|---|---|
| Un compte local diferent a cada PC; canviar una contrasenya vol dir anar equip per equip | Un compte per persona, creat una vegada; si algú se'n va, es desactiva i perd l'accés a tot |
| Els permisos de les carpetes compartides s'han de repetir a cada servidor | Permisos per **grups** (G_Comercial, G_Direccio…) aplicats a tots els recursos |
| Configuració manual de cada PC | **GPO**: fons, unitats de xarxa mapades, bloqueig d'USB, actualitzacions, contrasenyes segures… aplicades automàticament per OU |
| No hi ha registre central de qui entra on | Auditoria centralitzada d'inicis de sessió |

**Què aporta a l'empresa de l'enunciat:** té cinc departaments amb usuaris que poden canviar d'equip. Amb el domini, un comercial pot iniciar sessió a qualsevol PC amb el seu compte, i informàtica gestiona tots els equips des d'un sol lloc. Al meu entorn s'ha creat el domini `joan11.local` i el **Windows 11 i l'Ubuntu ja hi estan units** (apartats 5.6 i 5.7).

**Inconvenient:** el controlador de domini es converteix en un servei crític. A l'empresa caldrien dos controladors perquè, si un cau, els usuaris puguen continuar iniciant sessió.

L'enunciat diu que la implantació completa de dominis i polítiques (OU, GPO) correspon a fases posteriors (RA4/RA5). **S'ha creat el domini i s'hi han unit els dos clients**, el Windows 11 (apartat 5.6) i l'Ubuntu (apartat 5.7). No s'han creat OU, grups, permisos ni directives: només hi ha les dues directives que Windows crea per defecte.

### 4.3 Configuració: nom, usuari d'administració, xarxa i creació del domini

| Ítem | Valor |
|---|---|
| Nom d'equip | `DC-JOAN11` (abans `WIN-7CG1O7V1DFS`, el nom aleatori de la instal·lació; canviat amb `Rename-Computer` i reinici) |
| Xarxa | IP manual `192.168.11.10/24`, porta d'enllaç `192.168.11.1`, **DHCP: no** |
| Rols | **Serveis de domini d'Active Directory** (`Install-WindowsFeature` → `Success=True`) |
| Domini | **`joan11.local`**, NetBIOS `JOAN11`, bosc i domini nivell Windows Server 2016 (`Install-ADDSForest`). Un sol DC, que fa també de catàleg global |
| Usuari d'administració | `JOAN11\administrador11`, membre d'**Admins. del dominio** i d'**Administradores** (Builtin). En promocionar, l'usuari local passa a ser del domini però **no** entra sol a *Admins. del dominio*: s'hi ha afegit a mà (`Add-ADGroupMember`). El compte `Administrador` integrat del domini el crea Windows en promocionar, però no s'utilitza |
| Contrasenya del mode de restauració (DSRM) | Definida en la promoció i guardada fora del repositori |

Evidència: [`evidencies/t5-winserver-domini-copia.txt`](evidencies/t5-winserver-domini-copia.txt) (sense retocar)

```text
Domini            : joan11.local          NetBIOSName : JOAN11
DomainMode        : Windows2016Domain     PDCEmulator : DC-JOAN11.joan11.local
HostName          : DC-JOAN11.joan11.local   IPv4Address : 192.168.11.10   IsGlobalCatalog : True
Serveis: ADWS, KDC, Netlogon, NTDS → Running
```

| | |
|---|---|
| ![Rols instal·lats](evidencies/captures/t5-ws-01-rols-instal-lats.png) | ![Administrador del servidor amb els rols del domini](evidencies/captures/t5-ws-02-dc-rols.png) |
| Instal·lació dels rols i canvi de nom | El servidor ja com a DC, amb els rols en estat correcte |

![administrador11 a Admins. del dominio](evidencies/captures/t5-ws-04-admins-domini.png)

### 4.4 Còpia de la configuració al TrueNAS. Què és interessant copiar i què no

> **Pregunta de l'enunciat:** *Realitza les còpies de les configuracions i/o sistemes que consideres al servidor corresponent. Què és interessant copiar i què no?*

Còpia feta a mà en un PowerShell com a administrador: s'exporta la configuració, es comprimeix i es deixa per **SMB** a `\\192.168.11.5\backups\winserver` amb l'usuari `backup_user`. Al final es compara el SHA-256 del fitxer local amb el del NAS.

| Interessant copiar | Per què |
|---|---|
| Configuració de xarxa i rutes | Per a refer l'equip amb la mateixa IP i porta d'enllaç |
| Rols i característiques instal·lats | Es tornen a instal·lar amb una ordre |
| Usuaris i grup d'administradors | Saber qui administra l'equip |
| Actualitzacions i programari instal·lat | Deixar l'equip al mateix nivell després de reinstal·lar |
| Regles del tallafocs (`netsh advfirewall export`) i polítiques de seguretat (`secedit`) | És la configuració de seguretat, la més laboriosa de refer a mà |
| **Estat del sistema** (base de dades d'Active Directory) amb `wbadmin start systemstatebackup` | Si cau el DC, és el que permet recuperar els usuaris i equips del domini. Ocupa diversos GB, per això es proposa quan hi haja un disc de còpies més gran |

| No interessant copiar | Per què |
|---|---|
| La imatge sencera del disc (~15 GB ocupats) | No cap al pool de còpies de 5 GB i reinstal·lar + aplicar la configuració és més ràpid |
| Fitxers temporals, memòria virtual (`pagefile.sys`) o hibernació | No tenen informació útil i ocupen molt |
| La carpeta `C:\Windows` | Es recupera reinstal·lant des de la ISO |

**Resultat:** `DC-JOAN11-config-20261116-1239.zip`, **29 KB**, SHA-256 `688A8913…EA47CB` **idèntic al local i al NAS** (la còpia ha arribat sencera).

![Còpia del Windows Server al TrueNAS](evidencies/captures/t5-ws-03-copia-truenas.png)

> L'error en roig de la captura (`Get-LocalGroupMember: No se encontró el grupo S-1-5-32-544`) és perquè un controlador de domini no té grups locals. En un DC, el grup que s'ha de llegir és *Administradores* del domini (`Get-ADGroupMember`).

## 5. Clients: Windows 11 i Ubuntu

### 5.1 Windows 11 (`192.168.11.20`)

> La primera instal·lació va quedar inservible per la incidència de l'apartat 5.3 i s'ha **reinstal·lat**. Les dades d'aquesta taula són de la VM actual. Evidència: [`evidencies/t5-win11-estat.txt`](evidencies/t5-win11-estat.txt)

| Ítem | Valor |
|---|---|
| Versió | **Windows 11 Pro 23H2**, build `10.0.22631`, 64 bits (`Get-ComputerInfo`) |
| ISO i llicència | `w11.iso` (es-ES, conté totes les edicions; s'ha triat l'índex 6, *Pro*) · SHA-256 `5210deed…9dc8` (N/C contra la font oficial: Microsoft no publica el hash de la ISO). Instal·lada amb la clau genèrica d'instal·lació de Pro, que **no activa** Windows: per a un ús real caldria una llicència Pro (o volum/KMS en una empresa) |
| Mètode | Instal·lació desatesa de VirtualBox (`VBoxManage unattended install`): idioma, zona horària, nom d'equip i usuari d'administració |
| VM | 2 vCPU, 4 GB, disc de 80 GB (VDI amb `nonrotational on` i `discard off`, vegeu la [Tasca 7](Tasca7.md)), **UEFI**, Guest Additions 7.0.20 |
| Firmware, arrencada i disc | **UEFI + Secure Boot + TPM 2.0** · arrencada: disc · **GPT**: recuperació 0,3 GB, EFI 0,1 GB, MSR 0,1 GB, `C:` 79,5 GB · **NTFS**. **Per què:** Windows 11 **exigeix** UEFI, Secure Boot i TPM 2.0. A la VM s'han afegit el TPM virtual i les claus de Secure Boot. NTFS és l'únic sistema de fitxers on s'instal·la Windows |
| **TPM / Secure Boot** | **TPM 2.0** virtual (`TpmPresent/Ready/Enabled: True`) i **Secure Boot actiu** (`Confirm-SecureBootUEFI: True`), amb les claus de Microsoft carregades a la NVRAM de la VM (`VBoxManage modifynvram ... enrollmssignatures / enrollorclpk`). Ara compleix els requisits oficials de Windows 11, cosa que la primera instal·lació no feia |
| Nom d'equip | `W11-CLIENT11` |
| Usuaris | `Administracion11` (administrador local) · `Cliente11` (usuari estàndard) · `Administrador` integrat **desactivat** |
| Teclat | Espanyol (es-ES) |
| Xarxa | IP manual `192.168.11.20/24`, gw `192.168.11.1` (OPNsense), **DHCP: no**. Respon el ping al tallafocs i al TrueNAS i té eixida a Internet (`Test-NetConnection www.gva.es -Port 443` → `True`) |
| **Domini** | **Unit a `joan11.local`**. Vegeu l'apartat 5.6 |
| Actualitzacions | Vegeu l'apartat 5.4 |

![TPM 2.0 i Secure Boot actius](evidencies/captures/t5-w11-07-tpm-secureboot.png)

### 5.2 Ubuntu (`192.168.11.25`)

Evidència: [`evidencies/t5-ubuntu-estat.txt`](evidencies/t5-ubuntu-estat.txt)

| Ítem | Valor |
|---|---|
| Versió | **Ubuntu 26.04.1 LTS**, nucli 7.0.0-30-generic |
| ISO | `ubuntu-26.04.1-desktop-amd64.iso` · SHA-256 `601e30fb…1f` **coincideix** amb `releases.ubuntu.com/26.04.1/SHA256SUMS` |
| VM | 1 vCPU, 2 GB, 25 GB + 7 discos de 512 MB per al RAID (Tasca 6) |
| Firmware, arrencada i disc | BIOS · arrencada: **Disc primer** (abans arrencava l'instal·lador perquè la ISO anava primer) · GPT: BIOS boot 1 MB + arrel 25 GB · **ext4**. **Per què:** Opció per defecte d'Ubuntu. Els 7 discos de 512 MB són per als RAID de la Tasca 6 |
| Nom d'equip | `ubuntu-client11` (abans `joan11-VirtualBox`) |
| Usuari d'administració | `joan11` (grup `sudo`) |
| Xarxa | Connexió NetworkManager **`lan-estatica`**: manual `192.168.11.25/24`, gw `192.168.11.1`. La connexió de netplan per DHCP queda amb `autoconnect no` |
| Actualitzacions | `apt` va informar de "0 actualitzacions" en iniciar sessió. `apt update` va fallar per l'hora (vegeu sota) |
| Programari afegit | `openssh-server` (administració remota), `mdadm` (RAID), `sysstat` (mesures), i per al domini `realmd`, `sssd`, `adcli` i `krb5-user` |
| **Domini** | **Unit a `joan11.local`**. Vegeu l'apartat 5.7 |

**Problemes trobats i resolts:**
1. **Sense xarxa en arrencar**: la connexió esperava DHCP i a la LAN ja no n'hi ha. `nmcli con mod` sobre la connexió generada per netplan no es mantenia, i per això s'ha creat la connexió pròpia `lan-estatica`.
2. **`apt update`: "El fitxer de publicació no és vàlid encara"**: rellotge endarrerit en reprendre la VM. Es corregeix l'hora per HTTP.
3. **Arrencava l'instal·lador d'Ubuntu**: la ISO seguia al lector amb prioritat d'arrencada. ISO extreta i ordre `disk` primer.
4. **`sudo` tardava minuts**: després de canviar el hostname, el nom nou no estava a `/etc/hosts` i `sudo` esperava fins a esgotar el temps de cerca del nom. Afegit `127.0.1.1 ubuntu-client11` (de minuts a 0,4 s).

### 5.3 Incidència d'arrencada real al Windows 11 (punt 5 de la tasca)

| Pas | Detall |
|---|---|
| **Estat inicial** | Windows 11 funcionant (s'hi havien recollit les proves de xarxa de la Tasca 4 a les 12:22). Canvi de nom a `W11-CLIENT11` pendent de reinici |
| **Símptoma** | En reiniciar (12:24), Windows no arrenca: "Diagnosticando su PC" → "Intentando realizar reparaciones" → **"Reparación automática no pudo reparar tu PC"**. Si s'escull *Continuar*, torna a fallar ("Tu PC no se inició correctamente") |
| Hipòtesi 1: disc o sistema de fitxers danyat | **Descartada.** `chkdsk C:` des de la consola de recuperació (WinRE): *"Se examinó el sistema de archivos sin encontrar problemas"*, 0 KB en sectors defectuosos |
| Registre de la reparació | `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`: totes les proves (disc, registre, estat d'arrencada…) són correctes, però la **causa principal** és l'**aturada `c000021a`**, paràmetre `0xc000000d`: *"Un archivo de arranque imprescindible está dañado"*. La reparació de fitxers falla amb el codi `0x57` |
| Hipòtesi 2: una actualització a mitges | `c000021a` vol dir que ha mort un procés crític (winlogon o csrss). Els binaris crítics tenen les dates originals, però existeix **`C:\Windows\WinSxS\pending.xml` amb l'hora exacta del reinici**. És a dir, Windows Update havia deixat operacions de manteniment pendents i el sistema falla en aplicar-les durant l'arrencada. **Probable** |
| Solució aplicada (1r intent) | `dism /Image:C:\ /Cleanup-Image /RevertPendingActions` → *"La operación se completó correctamente"*. El DISM programa la reversió per a l'arrencada següent |
| Resultat | **Encara no arrenca.** L'arrencada següent torna a acabar en "Tu PC no se inició correctamente" |
| Comprovació (2n intent) | Des de la consola de WinRE: `pending.xml` **torna a existir**, amb data 12:32 (l'ha regenerat la mateixa reversió del DISM). Es reanomena a `pending.xml.bak` (no s'esborra, per poder tornar enrere) |
| Resultat | **Continua sense arrancar** ("Tu PC no se inició correctamente"). Per tant, `pending.xml` no era l'única causa |
| 3r intent | WinRE → *Desinstalar las actualizaciones* → *Desinstalar la última actualización de calidad* → **"Surgió un problema y no será posible desinstalar la última actualización"**. Sense punts de restauració ni instantània de la VM, no queden més vies de reparació raonables |
| **Solució final** | **Reinstal·lació** des de la ISO (el client no té dades úniques i la configuració està documentada). El disc avariat es conserva com a `Win11-avariat-c000021a.vdi` per si calguera recuperar-ne algun fitxer. Aprofitant la reinstal·lació, s'afig a la VM **TPM 2.0 i Secure Boot**, que eren la mancança detectada a l'apartat 5.1 |
| Retorn | Abans de cada intent es va fer una instantània de la VM (`abans-reparacio-c000021a`). A la VM nova es fa una instantània just després de configurar-la, que és la via de recuperació davant d'una actualització fallida (punt 4 de la tasca) |

| | |
|---|---|
| ![Reparació automàtica fallida](evidencies/captures/t5-w11-01-reparacio-fallida.png) | ![SrtTrail: causa c000021a](evidencies/captures/t5-w11-02-srttrail-causa.png) |
| Símptoma | Causa registrada a `SrtTrail.txt` |
| ![pending.xml a l'hora del reinici](evidencies/captures/t5-w11-03-pending-xml.png) | ![DISM RevertPendingActions](evidencies/captures/t5-w11-04-dism-revert.png) |
| `pending.xml` creat a les 12:24 | Reversió de les accions pendents amb DISM |
| ![pending.xml regenerat](evidencies/captures/t5-w11-05-pending-regenerat.png) | ![Desinstal·lar l'actualització falla](evidencies/captures/t5-w11-06-desinstal-falla.png) |
| `pending.xml` regenerat a les 12:32 | No es pot desinstal·lar l'última actualització |

**Lliçó apresa:** el `Restart-Computer -Force` reinicia encara que Windows Update estiga treballant en segon pla. En un equip que fa temps que no s'actualitza (l'últim paquet era de desembre de 2023), abans de reiniciar s'ha de comprovar que no hi ha cap actualització en curs (*Configuración → Windows Update*), o fer una instantània de la VM abans d'un canvi.

### 5.4 Actualització del Windows 11 i via de recuperació (punt 4 de la tasca)

Després de la incidència de l'apartat 5.3, l'actualització es fa amb una via de retorn preparada i comprovant que no queda cap operació pendent abans de reiniciar.

| Pas | Detall |
|---|---|
| Via de recuperació | Instantània de la VM `w11-configurat-abans-actualitzar` (equip configurat i amb la còpia al TrueNAS ja feta). Si l'actualització falla, es torna a aquest estat en segons |
| Eina | Ordres de PowerShell, com a administrador, sobre l'API de Windows Update (`Microsoft.Update.Session`), instal·la les actualitzacions de qualitat i de seguretat i **omet les de característiques** (canvi de versió), i ho registra tot amb l'hora |
| 1a ronda (16:45-16:52) | 5 actualitzacions, totes amb codi 2 (correcte): plataforma de Windows Security KB5007651, eina d'eliminació de programari maliciós KB890830, definicions de Defender 1.463.329.0, KB4023057 i l'acumulativa 2023-12 KB5033375. No demana reinici |
| Comprovació | Reinici i arrencada correcta (16:53), `pending.xml` no existeix, la xarxa i l'accés al NAS funcionen. Windows Update ofereix 2 actualitzacions més: plataforma de Defender KB4052623 i l'**acumulativa KB5068865** |
| Comprovació abans de reiniciar | Abans de reiniciar es comprova que no hi ha operacions pendents (`pending.xml`, clau `RebootRequired`) i que el servei de manteniment (`TrustedInstaller`/`TiWorker`) ha acabat. **Error meu en la 1a ronda:** vaig llançar el reinici en la mateixa ordre que la comprovació i `TiWorker` encara treballava. Com que era un reinici normal (no `-Force`), Windows va acabar el manteniment en apagar-se i va arrencar bé, però és justament el que va provocar la incidència de l'apartat 5.3 |
| 2a ronda (16:59-17:30) | Nova instantània abans de l'acumulativa. Plataforma de Defender KB4052623 i **acumulativa KB5068865**, totes dues amb codi 2. Aquesta vegada **sí demana reinici** |
| Comprovació final | Reinici normal (`shutdown /r`) a les 17:30 i arrencada correcta a les 17:33. **Build 22631.6199** (abans 22631.2861). En arrencar, `pending.xml` encara existeix (tasques de manteniment posteriors al reinici); es deixa acabar **sense tornar a reiniciar** i a les 17:41 ja no hi és. Xarxa, accés al TrueNAS i Guest Additions funcionen |
| Resultat | L'equip queda amb l'última acumulativa publicada per a 23H2 (el suport de 23H2 Pro ja ha acabat). El pas següent seria l'actualització de característiques a 24H2/25H2, que s'ha omés de manera conscient: és un canvi de versió i no forma part d'aquesta fase |

Evidència: [`evidencies/t5-win11-actualitzacio.txt`](evidencies/t5-win11-actualitzacio.txt)

### 5.5 Còpies dels clients (què es copia i què no)

| Client | Mètode | Es copia | No es copia (i per què) |
|---|---|---|---|
| Ubuntu | A mà: `tar` + `scp` a `backup_user@192.168.11.5` amb contrasenya → `ubuntu/` (apartat 2) | Connexions de xarxa (NM i netplan), `hosts`, `fstab`, `mdadm.conf`, `sshd_config`, repositoris, perfil i documents de l'usuari, **llista de paquets** (`dpkg --get-selections`) per a reinstal·lar-los d'una vegada | El sistema sencer: es reinstal·la des de la ISO en ~15 min i se li apliquen la configuració i la llista de paquets |
| Windows 11 | **Push** per SMB a `\\192.168.11.5\backups\win11` a mà, amb les mateixes ordres que el servidor (apartat 4.4) | Configuració de xarxa i rutes, usuaris locals i administradors, actualitzacions, programari instal·lat, tallafocs (`.wfw`, reimportable amb `netsh advfirewall import`) i polítiques de seguretat locals | La imatge completa del disc (~19 GB usats) no cap al pool de 5 GB. Com s'ha vist a l'apartat 5.3, reinstal·lar i aplicar aquesta configuració és el camí de recuperació |

Evidència Windows 11 (després de la reinstal·lació): [`evidencies/t5-win11-copia.txt`](evidencies/t5-win11-copia.txt): `W11-CLIENT11-config-20261116-1640.zip` (35,5 KB) amb el **mateix SHA-256 a l'equip i al NAS**.

![Còpia del Windows 11 al TrueNAS](evidencies/captures/t5-w11-08-copia-truenas.png)

Evidència Ubuntu: [`evidencies/t5-ubuntu-copia.txt`](evidencies/t5-ubuntu-copia.txt): `ubuntu-client11-20261116-1107.tar.gz` (6,8 KB) + `paquets-20261116-1107.txt` (43 KB).

### 5.6 Integració del Windows 11 al domini `joan11.local`

| Pas | Detall |
|---|---|
| Comprovacions prèvies | El client arriba al DC (`192.168.11.10`) i al port LDAP 389, troba el domini `joan11.local` i té la mateixa hora que el DC (Kerberos falla si la diferència passa de 5 minuts) |
| Unió | En un PowerShell com a administrador: `Add-Computer -DomainName joan11.local -Credential JOAN11\administrador11` → *"Unirse al dominio 'joan11.local'"* |
| Reinici | Abans de reiniciar es comprova que Windows Update no té res pendent (`pending.xml` no existeix, `TiWorker` aturat) i es reinicia amb `shutdown /r` |
| **Comprovació al client** | S'inicia sessió amb un **usuari del domini** (`JOAN11\administrador11`): `whoami` → `joan11\administrador11`, `Domain: joan11.local`, `PartOfDomain: True` |
| **Comprovació al DC** | `Get-ADComputer W11-CLIENT11` → compte d'equip `CN=W11-CLIENT11,CN=Computers,DC=joan11,DC=local`, `OperatingSystem: Windows 11 Pro`, `Enabled: True` |

Evidència: [`evidencies/t5-win11-domini.txt`](evidencies/t5-win11-domini.txt)

Els usuaris locals (`Administracion11` i `Cliente11`) continuen funcionant. Ara també hi poden iniciar sessió els usuaris del domini, i l'equip ja podria rebre polítiques (GPO), que no es configuren en aquesta fase.

### 5.7 Integració de l'Ubuntu al domini `joan11.local`

L'Ubuntu s'uneix al domini amb **realmd** i **SSSD**: `realmd` fa la unió i deixa configurat `sssd`, que és el servei que després valida els usuaris contra el controlador de domini.

| Pas | Detall |
|---|---|
| 1. Preparar la xarxa | A la connexió `lan-estatica` el client busca els noms al controlador de domini (`192.168.11.10`) amb el sufix `joan11.local` (`nmcli con mod lan-estatica ...`). Sense això no troba el domini. L'hora es posa igual que la del DC (Kerberos falla si la diferència passa de 5 minuts) |
| 2. Instal·lar els paquets | `sudo apt install realmd sssd sssd-tools adcli krb5-user samba-common-bin oddjob oddjob-mkhomedir packagekit` |
| 3. Descobrir el domini | `realm discover joan11.local` → `type: kerberos`, `server-software: active-directory`, `configured: no` |
| 4. Unir-se | `sudo realm join -U administrador11 joan11.local` i la contrasenya de l'administrador del domini → *"Successfully enrolled machine in realm"*. Crea el compte d'equip al DC i la clau de l'equip a `/etc/krb5.keytab` |
| 5. Carpeta personal automàtica | `sudo pam-auth-update --enable mkhomedir`: la primera vegada que entra un usuari del domini se li crea la carpeta `/home/usuari@joan11.local` |
| **Comprovació al client** | `realm list` → `configured: kerberos-member`. `id administrador11@joan11.local` mostra l'usuari i els seus grups del domini. Inici de sessió per SSH amb `administrador11@joan11.local` → `whoami` = `administrador11@joan11.local` i carpeta personal creada |
| **Comprovació al DC** | `Get-ADComputer UBUNTU-CLIENT11` → `CN=UBUNTU-CLIENT11,CN=Computers,DC=joan11,DC=local`, `Enabled: True` |

Evidència: [`evidencies/t5-ubuntu-domini.txt`](evidencies/t5-ubuntu-domini.txt)

L'usuari local `joan11` continua funcionant. Els usuaris del domini entren amb el nom complet (`usuari@joan11.local`).

## 6. Servidor d'infraestructura GNU/Linux: Debian 13 (`192.168.11.30`)

> Encara no s'ha decidit per a què s'utilitzarà (servidor web o de monitoratge, a la segona avaluació). Per això només s'han fet les tasques de l'enunciat: usuari d'administració, xarxa, programari base per a administrar-lo i còpia al servidor de còpies. No s'hi ha instal·lat cap servei.

Evidència: [`evidencies/t5-infra-estat.txt`](evidencies/t5-infra-estat.txt)

### 6.1 Instal·lació

| Ítem | Valor |
|---|---|
| Versió | **Debian GNU/Linux 13 (trixie)**, nucli 6.12.117, sense entorn gràfic |
| ISO | `debian-13.1.0-amd64-netinst.iso` · SHA-256 `658b28e2…568b3` (la mateixa que el Debian de comunicacions, comprovada amb `SHA256SUMS` de Debian) |
| Mètode | Instal·lació desatesa de VirtualBox (`VBoxManage unattended install`) amb selecció mínima de paquets: idioma, zona horària `Europe/Madrid`, nom d'equip i usuari d'administració |
| VM | `Servidor Infraestructura Debian`, al grup **PROJECTE ISO**: 1 vCPU, 1 GB RAM, disc de 12 GB (SSD) |
| Firmware, arrencada i disc | BIOS · arrencada: disc · MBR: arrel 11,3 GB + partició estesa amb *swap* 687 MB · **ext4**. **Per què:** opció per defecte de l'instal·lador de Debian. Un servidor sense dades pròpies no necessita res més, i amb 1 GB de RAM ZFS no tindria sentit |
| Requisits oficials | Debian sense escriptori: 512 MB de RAM i 4 GB de disc com a mínim. Té 1 GB i 12 GB per a deixar marge al servei que s'hi pose |
| Llicència | Lliure (DFSG), sense cost |
| Actualització | `apt full-upgrade` després d'instal·lar: el nucli passa de 6.12.43 a 6.12.117 |

### 6.2 Usuari d'administració

| Usuari | Permisos |
|---|---|
| `administrador11` | Usuari creat en la instal·lació i afegit al grup **`sudo`** (`usermod -aG sudo administrador11`). És el que s'utilitza per a administrar el servidor |
| `root` | Superusuari, només des de la consola |

S'ha instal·lat `sudo`, que la instal·lació mínima no porta. L'administració remota es fa per **SSH** (`openssh-server`, actiu).

### 6.3 Xarxa

| Ítem | Valor |
|---|---|
| Adaptador VirtualBox | Xarxa interna **`redjoan11`**, com la resta d'equips de la LAN |
| Interfície | `enp0s3`, **IP manual** `192.168.11.30/24`, porta d'enllaç `192.168.11.1` (OPNsense), a `/etc/network/interfaces` |
| Comprovació | Respon el TrueNAS (`ping 192.168.11.5`) i té eixida a Internet (`www.gva.es` pel port 443) |

**Problema trobat:** la instal·lació es fa amb un adaptador NAT de VirtualBox (per a descarregar els paquets) i després es passa a `redjoan11`. En canviar-lo, el client DHCP de la instal·lació (`dhcpcd`) seguia en marxa: posava una adreça `169.254.x.x` i reescrivia la configuració de xarxa, i el servidor no eixia a Internet. Solució: aturar `dhcpcd`, tornar a aplicar la configuració manual (`ifdown`/`ifup enp0s3`) i reiniciar per comprovar que la IP manual es manté i que `dhcpcd` ja no s'arrenca.

**Problema trobat:** `apt` intentava connectar per IPv6, que la LAN no té. S'ha forçat IPv4 a `/etc/apt/apt.conf.d/99ipv4` (`Acquire::ForceIPv4 "true";`).

### 6.4 Programari instal·lat

| Paquet | Per a què |
|---|---|
| `openssh-server` | Administració remota per SSH |
| `sudo` | Que `administrador11` puga administrar sense entrar com a `root` |

Com que encara no se sap quina funció tindrà, **no s'hi ha instal·lat cap servei** més. Quan es decidisca (servidor web o de monitoratge), s'instal·larà i es configurarà el programari corresponent.

### 6.5 Còpia de la configuració al TrueNAS

Al TrueNAS s'ha creat el dataset `Copias/backups/infra` amb una quota de 300 MB, propietat de `backup_user` (apartat 2). La còpia es fa a mà, igual que la dels altres Linux:

```text
sudo tar czf infra11-config-DATA.tar.gz /etc/network/interfaces /etc/hosts /etc/hostname /etc/resolv.conf \
     /etc/ssh/sshd_config /etc/apt/sources.list /etc/apt/apt.conf.d/99ipv4 /etc/fstab /etc/passwd /etc/group paquets.txt
scp infra11-config-DATA.tar.gz backup_user@192.168.11.5:/mnt/Copias/backups/infra/
```

| Es copia | No es copia (i per què) |
|---|---|
| Xarxa, nom, usuaris i grups, configuració de SSH, repositoris i la **llista de paquets** (`dpkg --get-selections`) | El sistema sencer: es reinstal·la des de la ISO en uns 15 minuts i s'hi aplica aquesta configuració |

**Resultat:** `infra11-config-20261117-1357.tar.gz` (5,9 KB), amb el **mateix SHA-256** al servidor i al TrueNAS (`f982863f…71dcd463c`).

![Servidor d'infraestructura: usuari, xarxa i còpia al TrueNAS](evidencies/captures/t5-infra-01-estat.png)

