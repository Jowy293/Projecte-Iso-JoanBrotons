# Tasca 5.2 · TrueNAS: servidor de còpies (`192.168.11.5`)

**RA:** ISO RA1 d-h · ISO RA3 f-h (còpies, quotes, recuperació)

## 1. Sistema

| Ítem | Valor |
|---|---|
| Versió | `TrueNAS-27.0.0-RC.1` (`midclt call system.version`). ISO `TrueNAS-27.0.0-RC.1.iso`, SHA-256 `515a0252…498e` |
| VM | 1 vCPU, 2 GB RAM, disc de sistema 18 GB (`boot-pool`) + **disc addicional de 5 GB** (`sdb`) per a les còpies |
| Hostname | `truenas11` · zona horària `Europe/Madrid` |
| Xarxa | `enp0s3` **estàtica** `192.168.11.5/24`, gw `192.168.11.1`, DNS `192.168.11.1` i `192.168.11.3` |
| Usuaris | `truenas_admin` (administrador, accés web i SSH) · `backup_user` (propietari de les còpies, home `/mnt/Copias/backups`) |
| Serveis | SSH (amb contrasenya per als administradors, amb clau per a les còpies) · SMB (recurs `backups`) · **FTP desactivat** (anava en clar i no feia falta) |

> **Requisit oficial:** TrueNAS recomana ≥8 GB de RAM per a ZFS. Aquí té 2 GB perquè el pool és de 5 GB i és un laboratori: funciona, però no és una configuració de producció.

**Problema trobat:** el TrueNAS estava en **DHCP** i agafava la `.55`, l'última IP del pool del MikroTik (`.5-.55`). Al README antic s'havia escrit `.55` com si fos una IP fixa. Ara està en estàtica a la `.5` (`interface.update` + `interface.commit` amb *rollback* automàtic de 60 s per si es perdia l'accés).

## 2. Espai de còpies: què, com i on

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
Copias/backups/historic       200M   lz4      ← còpies manuals antigues (27/10) conservades
```

- **Un dataset per equip amb quota** (RA3 g): si un equip genera còpies descontrolades, només omple la seua quota i no bloqueja les còpies de la resta. Les quotes s'han posat amb `zfs set quota=` perquè l'API de TrueNAS 27 exigeix un mínim d'1 GB.
- **Compressió LZ4**: els fitxers de configuració són text i es comprimeixen molt.
- El dataset antic `copias_de_seguiridad` (nom amb errata, compartit per SMB i FTP) s'ha eliminat després de copiar-ne el contingut a `historic/`.

### Com arriba cada còpia (el TrueNAS ha de ser accessible per a deixar-hi les còpies)

| Tipus d'equip | Mètode | Per què |
|---|---|---|
| Servidors Linux/BSD/RouterOS (OPNsense, MikroTik, Debian, Proxmox) | **Pull per SSH** des del TrueNAS amb la clau `backup_user@truenas11` ([`scripts/copia-servidors.sh`](../scripts/copia-servidors.sh)) | Els servidors no guarden cap credencial per a escriure al NAS. Si un servidor queda compromés, no pot esborrar les còpies. Les claus estan limitades amb `from="192.168.11.5"` |
| Client Ubuntu | **Push per SFTP/SCP** a `backup_user@192.168.11.5` | L'usuari deixa la seua còpia quan vol |
| Windows (Server i 11) | **Push per SMB** al recurs `\\192.168.11.5\backups` (usuari `backup_user`) | Protocol natiu de Windows (`robocopy`, Explorador, `wbadmin`) |

Per indicació del professorat, **les còpies no s'automatitzen** (no hi ha cron ni snapshots periòdics). Es fan a mà quan cada equip està acabat:

```bash
# Al TrueNAS, com a backup_user
sudo -u backup_user /mnt/Copias/backups/scripts/copia-servidors.sh tots     # o opnsense | mikrotik | debian | proxmox
```

L'script verifica que el fitxer no estiga buit i mostra la mida i el `sha256`. Si una còpia ix buida, l'esborra i diu `ERROR`. Va passar de veritat després del reset del MikroTik: havia canviat la clau de host.

## 3. Recuperació provada
Les tres recuperacions de la [Tasca 5.1 §7](T5-1-comunicacions.md#7-errada-controlada-i-recuperació) s'han fet **a partir d'aquestes còpies**: el MikroTik es va descarregar la seua per SFTP (`/tool fetch mode=sftp ... user=backup_user`), i al Debian i a l'OPNsense el TrueNAS els va retornar el fitxer per SSH.
