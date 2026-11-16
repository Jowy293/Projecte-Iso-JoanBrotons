# Tasca 5.3 · Proxmox VE (`192.168.11.17`)

**RA:** ISO RA1 d-h · ISO RA3 (còpia)

> **Abast acordat amb el professorat:** a l'entorn individual, el Proxmox **només ha de tenir configurada la xarxa** (i l'administració). No s'hi creen màquines dins perquè el portàtil no té recursos per a virtualització imbricada amb un Windows Server a dins. Per això el Windows Server 2025 s'ha instal·lat com a VM de VirtualBox independent ([Tasca 5.4](T5-4-windows-server.md)).

Evidències: [`evidencies/t5-proxmox-estat.txt`](../evidencies/t5-proxmox-estat.txt) · [`evidencies/t5-proxmox-copia.txt`](../evidencies/t5-proxmox-copia.txt)

## 1. Sistema

| Ítem | Valor |
|---|---|
| Versió | `pve-manager/9.2.2` (nucli 7.0.2-6-pve), base Debian 13 trixie |
| ISO | `proxmox-ve_9.2-1.iso` · SHA-256 `4e88fe41…f0395` **coincideix** amb `enterprise.proxmox.com/iso/SHA256SUMS` |
| VM VirtualBox | 1 vCPU amb **VT-x imbricat activat** (*nested*), 2 GB RAM, 30 GB |
| Hostname | `pve1.joan11.local` |

## 2. Usuaris d'administració

| Usuari | Realm | Permisos |
|---|---|---|
| `root@pam` | PAM | Superusuari (necessari per al clúster i la consola) |
| `administrador11@pam` | PAM | Rol `Administrator` sobre `/` (ACL). Usuari Linux creat amb `useradd` i afegit a Proxmox amb `pveum user add` |

Accés web: `https://192.168.11.17:8006`.

## 3. Xarxa

```text
auto vmbr0
iface vmbr0 inet static
        address 192.168.11.17/24
        gateway 192.168.11.1        # abans 192.168.11.2 (MikroTik)
        bridge-ports nic0
        bridge-stp off
        bridge-fd 0
```

- `vmbr0` és el pont Linux on es connectarien les VM i contenidors: tindrien IP a la mateixa LAN 192.168.11.0/24.
- DNS: `192.168.11.1` (OPNsense) i `192.168.11.3` (Debian), domini de cerca `joan11.local` (abans `joan.com`).
- Canvis aplicats amb `ifreload -a`, sense reiniciar.

## 4. Repositoris i actualització

- S'han desactivat `pve-enterprise` i `ceph` (sense subscripció donen error 401) i s'ha afegit `pve-no-subscription`. Els fitxers originals estan a `/root/repos-desactivats/`.
- `apt update` funciona, i hi ha **130 paquets actualitzables**. **No s'ha fet `dist-upgrade`** per mantindre l'abast acordat (només xarxa). Queda pendent de decidir amb el professorat.
- Problema trobat: `apt update` fallava amb "signatura no vàlida fins a …" perquè el rellotge anava endarrerit (NTP bloquejat a l'aula i VM represa des d'estat guardat). S'ha resolt amb [`scripts/httptime.sh`](../scripts/httptime.sh).

## 5. Còpia de la configuració

`copia-servidors.sh proxmox` → `proxmox/pve1-config-20261116-1106.tar.gz` (13,8 KB):

| Es copia | Per què |
|---|---|
| `/etc/pve/` (storage.cfg, user.cfg, `qemu-server/`, `lxc/`, firewall, certificats i claus de `priv/`) | És tota la configuració del node i del clúster (sistema de fitxers `pmxcfs`). Amb això es reconstrueix el node després de reinstal·lar |
| `/etc/network/interfaces`, `hosts`, `hostname`, `resolv.conf` | Xarxa i identitat del node |
| `/etc/apt/sources.list.d/` | Repositoris |

**No es copia:** el sistema operatiu (es reinstal·la des de la ISO en ~10 min) ni els discos de les VM. Les VM es copiarien amb `vzdump` cap a un emmagatzematge separat (el TrueNAS per NFS o un Proxmox Backup Server), no amb un `tar`.
**Compte:** la còpia conté claus privades (`priv/`): només la pot llegir `backup_user` (permisos 750 al dataset).

## 6. Clúster, contenidors i migració: disseny (no executat)

La rúbrica permet "registrar el disseny o la simulació autoritzada si no hi ha nodes suficients". Amb un sol node a l'entorn individual:

- **Clúster:** caldrien ≥3 nodes (o 2 + QDevice) perquè hi haja **quòrum**. Amb 2 nodes, si un cau, l'altre perd el quòrum i bloqueja `/etc/pve`. Ordres: `pvecm create clusterjoan11` al primer node i `pvecm add 192.168.11.17` als altres. La xarxa del clúster (corosync) hauria d'anar separada de la LAN dels usuaris.
- **Gestió conjunta / migració / HA:** amb clúster, tots els nodes es gestionen des d'una web (gestió conjunta). La **migració** mou una VM d'un node a un altre: en calent si el disc està en emmagatzematge compartit, en fred copiant el disc si no. L'**alta disponibilitat (HA)** reinicia automàticament la VM en un altre node si el seu cau, i necessita quòrum i emmagatzematge compartit (NFS/iSCSI al TrueNAS o Ceph).
- **Contenidor vs màquina virtual:** el contenidor LXC comparteix el nucli del host: arrenca en segons i ocupa centenars de MB, però només pot executar Linux i aïlla menys. La VM (KVM) té nucli propi: pot executar Windows o BSD i aïlla més, però costa més RAM i disc. A l'empresa: **LXC** per a serveis Linux lleugers (DNS, monitoratge, web interna), i **VM** per al Windows Server, el tallafocs virtual o qualsevol cosa que necessite un nucli diferent.
- **Avantatges de virtualitzar servidors:** consolidació (menys maquinari i consum), instantànies abans d'un canvi, còpia i restauració de la VM sencera, migració. **Inconvenients:** un host que cau s'emporta totes les seues VM (cal clúster/HA), sobrecost de RAM i E/S, i una complexitat i llicències (Windows per nucli) que cal planificar.
