# Tasca 5.1 · Servidors de comunicacions (OPNsense, MikroTik, Debian + nftables)

**RA:** ISO RA1 d-h · ISO RA3 (còpia i recuperació) · ISO RA6 (registres)

## 0. Decisió de disseny: una sola LAN, tres passarel·les, cap DHCP a la LAN

Els tres servidors de comunicacions comparteixen la mateixa xarxa interna `redjoan11` (192.168.11.0/24):

| Equip | LAN (estàtica) | WAN | Rol |
|---|---|---|---|
| OPNsense 26.7 | `192.168.11.1/24` | DHCP de l'aula (`172.16.222.x`, adaptador pont) | **Passarel·la per defecte** de tots els equips + DNS (Unbound) |
| MikroTik RouterOS 7.24.5 | `192.168.11.2/24` | DHCP de l'aula | Passarel·la alternativa (contingència) |
| Debian 13 + nftables | `192.168.11.3/24` | DHCP de l'aula | Passarel·la alternativa + DNS secundari (dnsmasq) |

- **Només les WAN dels servidors de comunicacions van per DHCP.** Tota la resta d'equips té IP manual (vegeu [Tasca 4](T4-xarxa.md)).
- **Cap servidor fa DHCP a la LAN.** Al principi el MikroTik repartia el rang `.5-.55`. Això provocava que el TrueNAS acabara a la `.55` i que el **propi OPNsense** agafara la `.50` a la seua LAN, amb la ruta per defecte cap al MikroTik. Amb tres passarel·les a la mateixa LAN, si hi ha més d'un DHCP, cada client acaba amb una passarel·la diferent a l'atzar.
- Per a provar el MikroTik o el Debian, el client canvia la passarel·la (`ip route replace default via 192.168.11.2`). Així es fa a les proves de sota.

## 1. Comprovacions comunes abans d'instal·lar

| Sistema | ISO | SHA-256 (calculat a l'amfitrió) | Arquitectura / requisits |
|---|---|---|---|
| OPNsense | `OPNsense.iso` | `1efd5dc9…8d5dcd`* | amd64, 1 vCPU, ≥2 GB RAM (s'han assignat 3 GB), 25 GB |
| MikroTik | `mikrotik-7.24.5.iso` | `4bff16b8…aec02` | x86_64, 512 MB, 2 GB disc |
| Debian | `debian-13.1.0-amd64-netinst.iso` | `658b28e2…568b3` | amd64, 2 GB, 20 GB |

Llistat complet de hash: [`evidencies/iso-sha256.txt`](../evidencies/iso-sha256.txt). Com es comprova: s'ha de comparar el hash calculat amb el que publica el fabricant (`SHA256SUMS` de Debian, `.sha256` d'OPNsense, `CHECKSUMS` de MikroTik a la pàgina de descàrregues).
\* Valor complet a l'evidència.

## 2. OPNsense (`192.168.11.1`)

| Ítem | Configuració |
|---|---|
| Versió | `OPNsense 26.7 (amd64)` (`opnsense-version`) |
| Hostname | `opnsense11` |
| Usuari d'administració | `root` (reset des de la consola, opció 3). Accés web `https://192.168.11.1` i SSH només des de la LAN |
| WAN `em0` | DHCP (pont `eno1`) → `172.16.222.184/24`, gw `172.16.222.1` |
| LAN `em1` | Estàtica `192.168.11.1/24`, sense gateway |
| NAT | *Outbound* automàtic: `nat on em0 from (em1:network) -> (em0:0)` |
| DNS | Unbound al port 53 per als clients de la LAN |
| DHCP | **Desactivat** (dnsmasq sense rangs) |
| Regles LAN | 1) `block` TCP/23 amb *log* (prova) · 2) `pass` LAN → any amb *log* |

**Problemes trobats i resolts:**
1. La LAN tenia la `.50` encara que el `config.xml` deia `.1`: hi havia un `dhclient` llançat per un procés `daemon -r` sobre `em1`, i ho re-aplicava a partir del *lease* guardat a `/var/db/dhclient.leases.em1`. Solució: matar el `daemon`, esborrar el *lease*, reassignar la IP des de la consola (opció 2) i reiniciar per comprovar que es manté.
2. La ruta per defecte anava pel MikroTik (`192.168.11.2`), també heretada del DHCP. Després de la correcció: `default 172.16.222.1 UGS em0`.

Extracte de la configuració (sense claus ni hash): [`configs/opnsense-extracte.xml`](../configs/opnsense-extracte.xml)

## 3. MikroTik (`192.168.11.2`)

| Ítem | Configuració |
|---|---|
| Versió | RouterOS **7.24.5 (stable)**, x86_64 (`/system resource print`) |
| Identitat | `MikroTik-11` |
| Usuaris | `administrador11` (grup *full*). `admin` **desactivat**. `backup` (grup `copies`: només `ssh,read,sensitive,test,ftp`, sense `write`, només des de `192.168.11.5`, amb clau SSH) |
| WAN `ether1` | Client DHCP → `172.16.222.213/24` |
| LAN `ether2` | `192.168.11.2/24` |
| NAT | `srcnat out-interface-list=WAN action=masquerade` (**no existia: per això no hi havia Internet a través del MikroTik**) |
| DNS | `allow-remote-requests=yes` (servidors dinàmics del DHCP de l'aula) |
| DHCP | Servidor `dhcp1` **desactivat**; pool reduït a `.200-.220` per si cal activar-lo en contingència |
| Firewall | input: establertes, ICMP, LAN, SSH/Winbox només des de 172.16.222.0/24, resta WAN *drop+log* · forward: establertes, **Telnet LAN→fora *drop+log* (`MK-BLOQ-TELNET`)**, LAN→WAN *accept*, WAN→LAN *drop+log* |

Configuració exportada (sense dades sensibles): [`configs/mikrotik-export.rsc`](../configs/mikrotik-export.rsc)

**Limitació detectada:** és la imatge x86 sense llicència (`ROUTER HAS NO SOFTWARE KEY`, mode de prova de 24 h). Per a un ús continu s'hauria d'utilitzar la imatge **CHR** (llicència gratuïta *free*, limitada a 1 Mbps per interfície) o comprar una llicència de nivell 4.

## 4. Debian 13 + nftables (`192.168.11.3`)

| Ítem | Configuració |
|---|---|
| Versió | Debian GNU/Linux 13 (trixie), nucli 6.12.113 |
| Hostname | `deb-comms11` |
| Usuaris | `administrador11` (afegit al grup `sudo`; abans no tenia permisos) i `root` |
| WAN `enp0s3` | DHCP per `ifupdown` (`/etc/network/interfaces`) |
| LAN `enp0s8` | `192.168.11.3/24` estàtica |
| Encaminament | `net.ipv4.ip_forward=1` persistent a `/etc/sysctl.d/99-router.conf` |
| Tallafocs | `/etc/nftables.conf` → [`configs/debian-nftables.conf`](../configs/debian-nftables.conf) (input i forward amb política `drop`, NAT `masquerade`, bloqueig de Telnet amb *log* `DEB-BLOQ-TELNET`) |
| DNS | `dnsmasq` només com a DNS per a la LAN (`no-dhcp-interface`) |
| SSH | `openssh-server` instal·lat (no ho estava) |

**Problemes trobats i resolts:**
1. `nftables.service` estava **inactive (dead)**: el fitxer tenia el NAT però no s'aplicava mai → la LAN no eixia per la `.3`. Solució: `systemctl enable --now nftables`.
2. La WAN tenia **dues IP** (`.194` i `.195`) perquè la gestionaven alhora `ifupdown` i NetworkManager. Solució: `/etc/NetworkManager/conf.d/10-ifupdown-gestiona.conf` amb `unmanaged-devices` per a `enp0s3` i `enp0s8`.
3. NTP (UDP/123) està bloquejat a la xarxa de l'aula i el rellotge quedava endarrerit (les VM es reprenen des d'estat guardat). Això feia fallar `apt` ("signatura no vàlida encara"). Solució: script [`scripts/httptime.sh`](../scripts/httptime.sh) amb un *timer* de systemd que agafa l'hora de la capçalera `Date` d'HTTP.

## 5. Connexió permesa i connexió bloquejada (amb registre)

Client: Ubuntu `192.168.11.25`. S'ha canviat la passarel·la a `.1`, `.2` i `.3` successivament ([`scripts/fwtest.sh`](../scripts/fwtest.sh)).
Evidència: [`evidencies/t5-proves-firewall-client.txt`](../evidencies/t5-proves-firewall-client.txt) i [`evidencies/t5-logs-firewalls.txt`](../evidencies/t5-logs-firewalls.txt)

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

## 6. Còpia de la configuració al servidor de còpies

La còpia es fa **manualment** quan la configuració està acabada: `copia-servidors.sh`, executat al TrueNAS, va a buscar la configuració per SSH amb clau. Detall a [Tasca 5.2](T5-2-truenas-copies.md).

| Equip | Què es copia | Fitxer al TrueNAS | Mida |
|---|---|---|---|
| OPNsense | `/conf/config.xml` (tota la configuració en un fitxer) | `opnsense/config-opnsense11-20261116-1046.xml` | 38 KB |
| MikroTik | `/export show-sensitive` (text, reimportable) | `mikrotik/mikrotik11-20261116-1052.rsc` | 2,4 KB |
| Debian | `tar` de `/etc/nftables.conf`, `interfaces`, `dnsmasq.d`, `sysctl.d`, `sshd_config`, `hosts`, NM i el *timer* d'hora | `debian-comms/deb-comms11-etc-…tar.gz` | 3,7 KB |

**Què NO es copia i per què:** la imatge sencera del disc (OPNsense 25 GB, Debian 20 GB) no cap al pool de 5 GB i no cal: reinstal·lar des de la ISO verificada + restaurar la configuració és més ràpid i ocupa uns quants KB.

## 7. Errada controlada i recuperació

Durant cada prova, el client Ubuntu executava [`scripts/probe.sh`](../scripts/probe.sh): fa un `wget` cada segon per la passarel·la provada i registra els canvis d'estat.

| Equip | Errada provocada | Recuperació | Caiguda observada pel client | Evidència |
|---|---|---|---|---|
| Debian | `rm /etc/nftables.conf; nft flush ruleset` (es perd el NAT) | Des del TrueNAS: `cat còpia.tar.gz \| ssh root@.3 "tar xzf - -C / etc/nftables.conf && systemctl restart nftables"` | **13 s** (10:40:33 → 10:40:46, 12 s eren d'espera) | [`t5-fallada-debian.txt`](../evidencies/t5-fallada-debian.txt) |
| OPNsense | S'esborra la regla *Default allow LAN to any* i es recarrega el filtre | Es restaura `config.xml` des del TrueNAS + `configctl filter reload` | **13 s** (10:52:59 → 10:53:12) | [`t5-fallada-opnsense.txt`](../evidencies/t5-fallada-opnsense.txt) |
| MikroTik | **Reset de fàbrica** `/system reset-configuration no-defaults=yes` | Consola: IP temporal → `/tool fetch mode=sftp` de la còpia del TrueNAS → `/ip address remove [find]; /import restore.rsc` → tornar a crear els usuaris | **1 min 51 s** (10:49:45 → 10:51:36, inclou el reinici) | [`t5-fallada-mikrotik.txt`](../evidencies/t5-fallada-mikrotik.txt) |

**Lliçons apreses (reals, eixides de les proves):**
- `/export` del MikroTik **no inclou els usuaris ni les claus SSH**: després d'importar cal recrear `administrador11` i `backup`. Millora: guardar també un `/system backup` binari (inclou usuaris) a més de l'export de text.
- Després del reset, el MikroTik genera una **clau de host SSH nova** i la primera còpia posterior va fallar ("REMOTE HOST IDENTIFICATION HAS CHANGED"). És el comportament segur; es resol amb `ssh-keygen -R 192.168.11.2` un cop comprovat que el canvi és legítim.
- Al Debian i a l'OPNsense, la recuperació en si dura menys de 2 s; la major part de la caiguda és el temps a detectar el problema.
