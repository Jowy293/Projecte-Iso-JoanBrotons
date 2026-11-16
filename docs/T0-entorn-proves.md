# Tasca 0 · Entorn de proves individual

**RA:** FDM RA1 · **Hipervisor:** Oracle VirtualBox 7.0.20 sobre Linux Mint 22.3 (portàtil de classe)

## 1. Què simula l'entorn

Una reproducció "a escala" del sistema de l'empresa de l'enunciat, seguint l'esquema que va donar el professor per al muntatge individual: tres servidors de comunicacions alternatius, cap a una LAN interna on hi ha el NAS de còpies, el node de virtualització, el controlador de domini i dos clients. Esquema i adreçament: [Tasca 4](T4-xarxa.md).

## 2. Màquines virtuals i recursos assignats

| VM (nom a VirtualBox) | SO | vCPU | RAM | Disc(s) | Firmware | Xarxa VirtualBox |
|---|---|---|---|---|---|---|
| Servidor de Comunicaciones OPNsense | OPNsense 26.7 | 1 | 3 GB | 25 GB SATA | BIOS | Pont `eno1` + Interna `redjoan11` |
| MikroTik | RouterOS 7.24.5 x86 | 2 | 512 MB | 2 GB IDE | BIOS | Pont `eno1` + Interna `redjoan11` |
| Servidor de Comunicaciones Debian | Debian 13.1 | 1 | 2 GB | 20 GB SATA | BIOS | Pont `eno1` + Interna `redjoan11` |
| TrueNas(Datos) | TrueNAS 27.0.0-RC.1 | 1 | 2 GB | 18 GB (sistema) + **5 GB (còpies)** | BIOS | Interna `redjoan11` |
| Proxmox | Proxmox VE 9.2 | 1 (VT-x imbricat) | 2 GB | 30 GB | BIOS | Interna `redjoan11` |
| WinServer2025-DC | Windows Server 2025 Standard (Escriptori) | 2 | 3 GB | 50 GB SATA (SSD) | BIOS | Interna `redjoan11` |
| Windows 11 (Cliente) | Windows 11 Pro | 2 | 4 GB | 80 GB SATA | **EFI + TPM** | Interna `redjoan11` |
| Ubuntu(Cliente) | Ubuntu 26.04.1 LTS | 1 | 2 GB | 25 GB + 7×512 MB (RAID) | BIOS | Interna `redjoan11` |
| *(pendent)* Ubuntu Server monitoratge | — | — | — | — | — | Es farà en una tasca posterior |

**Suma si s'encenen totes:** 11 vCPU · **18,5 GB de RAM** · ~255 GB de disc reservat (en VDI dinàmics que creixen sota demanda).

## 3. Recursos físics de l'amfitrió i limitacions

Dades reals obtingudes amb `lscpu`, `free`, `lsblk`, `lsusb -t` i `/sys` ([`evidencies/inventari-host-classe.txt`](../evidencies/inventari-host-classe.txt)):

| Recurs | Portàtil de classe (ASUS ExpertBook B3605CCA) | Conseqüència per a l'entorn |
|---|---|---|
| CPU | Intel Core Ultra 5 125H · 14 nuclis / 18 fils · fins a 4,5 GHz · VT-x | Sobrada: amb totes les VM, la CPU està al 90 % lliure (vegeu T7) |
| RAM | 32 GB (31,3 GB útils) + 16 GB swap + zram | Totes les VM juntes (18,5 GB) caben, però el sistema queda amb ~11 GB i sense marge per a la memòria cau de disc |
| **Disc on hi ha les VM** | **Kingston A400 SATA 480 GB dins d'una caixa USB 3.0 (UAS, 5 Gbit/s)** · `/home` ext4 | **És el coll de botella.** El sistema arrenca d'aquest disc extern (el NVMe Samsung intern de 1 TB és del centre i no s'utilitza). Límit pràctic ~300 MB/s de lectura (mesurat) |
| Xarxa | Intel e1000e Gigabit (`eno1`) + Wi-Fi Realtek RTL8852BE | La WAN de les VM va en pont sobre `eno1` |
| Firmware | UEFI | — |

**Limitacions justificades:**
1. **Disc:** amb diverses VM arrencant o instal·lant alhora, l'SSD USB arriba al 85-90 % d'ús (mesurat durant la instal·lació del Windows Server). Per això les VM s'encenen per torns i les que no s'utilitzen es **guarden en estat** (*savestate*) en lloc de deixar-les enceses.
2. **RAM:** TrueNAS recomana 8 GB i Windows Server 4 GB. Aquí tenen 2 GB i 3 GB perquè, si no, no caben totes les VM. Funcionen per a un laboratori, no per a producció.
3. **Virtualització imbricada:** el Proxmox no pot allotjar el Windows Server amb 2 GB i VT-x imbricat sobre un disc USB. Per això, per indicació del professor, el Proxmox només té la xarxa i el Windows Server és una VM de VirtualBox.
4. **Xarxa de l'aula:** NTP (UDP/123) i ICMP cap a Internet estan filtrats. Això afecta l'hora de les VM i les proves amb `ping` (vegeu T5.1).

## 4. Problemes trobats en el muntatge i solució

| Problema | Causa | Solució |
|---|---|---|
| Diversos equips amb IP incorrecta (TrueNAS a `.55`, OPNsense LAN a `.50`) | El MikroTik feia de servidor DHCP a la LAN amb el rang `.5-.55` | DHCP desactivat a tots els routers. IP manual a tota la LAN |
| No hi havia Internet a través del MikroTik | Faltava la regla de NAT `masquerade` | Afegida + firewall complet |
| No hi havia Internet a través del Debian | `nftables.service` desactivat | `systemctl enable --now nftables` |
| `apt` falla amb "signatura no vàlida encara" | Rellotge endarrerit (NTP bloquejat, VM represes de *savestate*) | Sincronització per HTTP (`scripts/httptime.sh`) |
| L'Ubuntu arrencava l'instal·lador | La ISO seguia muntada i el DVD tenia prioritat d'arrencada | ISO extreta i ordre d'arrencada `disk` primer |
| Instal·lació del Windows Server penjada al 18 % amb el disc al 90 % | VM amb firmware EFI bloquejada en una E/S (vegeu T5.4) | Reinstal·lació amb BIOS i imatge aplicada amb DISM |
| Contrasenyes desconegudes (OPNsense, Proxmox, Windows Server) | No documentades | Restabliment pels mecanismes oficials (consola OPNsense opció 3, `chpasswd` des de la consola root de Proxmox) i reinstal·lació del Windows Server, que no tenia res configurat |
