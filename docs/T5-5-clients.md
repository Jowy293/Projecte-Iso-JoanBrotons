# Tasca 5.5 · Clients: Windows 11 i Ubuntu

**RA:** ISO RA1 d-h · ISO RA3 (còpia)

## 1. Windows 11 (`192.168.11.20`)

Evidència: [`evidencies/t5-win11-estat.txt`](../evidencies/t5-win11-estat.txt)

| Ítem | Valor |
|---|---|
| Versió | **Windows 11 Pro 23H2**, build `10.0.22631`, 64 bits (`Get-ComputerInfo`) |
| ISO | `w11.iso` · SHA-256 `5210deed…9dc8` (N/C contra la font oficial: Microsoft no publica el hash de la ISO) |
| VM | 2 vCPU, 4 GB, 80 GB, **UEFI**, Guest Additions 7.0.20 |
| TPM / Secure Boot | **No** (la VM no té TPM virtual i `Confirm-SecureBootUEFI` → no suportat). Windows 11 exigeix TPM 2.0 i Secure Boot: es va instal·lar saltant-se la comprovació. **Conseqüència:** Microsoft no garanteix les actualitzacions de característiques en equips sense TPM. **Correcció recomanada:** a VirtualBox 7, *Configuració → Sistema → TPM 2.0* i *Secure Boot*, abans de la propera reinstal·lació |
| Nom d'equip | `W11-CLIENT11` (abans `DESKTOP-BTD8EEA`) |
| Usuaris | `Administracion11` (administrador local) · `Cliente11` (usuari) · `Administrador` integrat desactivat |
| Xarxa | IP manual `192.168.11.20/24`, gw `192.168.11.1`, DNS `192.168.11.10` (DC) i `192.168.11.1`. Abans tenia `192.168.11.53` per DHCP del MikroTik |
| Actualitzacions | Últim paquet instal·lat: **KB5033375 (04/12/2023)**. Està **desactualitzat** |
| Domini | No s'uneix al domini en aquesta fase (opcional a la rúbrica; correspon a RA4/RA5). El DNS ja apunta al DC per a quan s'unisca |

## 2. Ubuntu (`192.168.11.25`)

Evidència: [`evidencies/t5-ubuntu-estat.txt`](../evidencies/t5-ubuntu-estat.txt)

| Ítem | Valor |
|---|---|
| Versió | **Ubuntu 26.04.1 LTS**, nucli 7.0.0-30-generic |
| ISO | `ubuntu-26.04.1-desktop-amd64.iso` · SHA-256 `601e30fb…1f` **coincideix** amb `releases.ubuntu.com/26.04.1/SHA256SUMS` |
| VM | 1 vCPU, 2 GB, 25 GB + 7 discos de 512 MB per al RAID (Tasca 6) |
| Nom d'equip | `ubuntu-client11` (abans `joan11-VirtualBox`) |
| Usuari d'administració | `joan11` (grup `sudo`) |
| Xarxa | Connexió NetworkManager **`lan-estatica`**: manual `192.168.11.25/24`, gw `192.168.11.1`, DNS `192.168.11.1, 192.168.11.3`. La connexió de netplan per DHCP queda amb `autoconnect no` |
| Actualitzacions | `apt` va informar de "0 actualitzacions" en iniciar sessió. `apt update` va fallar per l'hora (vegeu sota) |
| Programari afegit | `openssh-server` (administració remota), `mdadm` (RAID), `sysstat` (mesures) |

**Problemes trobats i resolts:**
1. **Sense xarxa en arrencar**: la connexió esperava DHCP i a la LAN ja no n'hi ha. `nmcli con mod` sobre la connexió generada per netplan no es mantenia, i per això s'ha creat la connexió pròpia `lan-estatica`.
2. **`apt update`: "El fitxer de publicació no és vàlid encara"**: rellotge endarrerit en reprendre la VM. Es corregeix l'hora per HTTP.
3. **Arrencava l'instal·lador d'Ubuntu**: la ISO seguia al lector amb prioritat d'arrencada. ISO extreta i ordre `disk` primer.
4. **`sudo` tardava minuts**: després de canviar el hostname no estava a `/etc/hosts` i `sudo` esperava el DNS. Afegit `127.0.1.1 ubuntu-client11` (de minuts a 0,4 s).

## 3. Còpies dels clients (què es copia i què no)

| Client | Mètode | Es copia | No es copia (i per què) |
|---|---|---|---|
| Ubuntu | **Push** per SCP amb clau, `copia-client-linux.sh` → `ubuntu/` | Connexions de xarxa (NM i netplan), `hosts`, `fstab`, `mdadm.conf`, `sshd_config`, repositoris, perfil i documents de l'usuari, **llista de paquets** (`dpkg --get-selections`) per a reinstal·lar-los d'una vegada | El sistema sencer: es reinstal·la des de la ISO en ~15 min i se li apliquen la configuració i la llista de paquets |
| Windows 11 | **Push** per SMB a `\\192.168.11.5\backups\win11` | Vegeu §4 | La imatge completa del disc (~25 GB usats) no cap al pool de 5 GB |

Evidència Ubuntu: [`evidencies/t5-ubuntu-copia.txt`](../evidencies/t5-ubuntu-copia.txt): `ubuntu-client11-20261116-1107.tar.gz` (6,8 KB) + `paquets-20261116-1107.txt` (43 KB).
