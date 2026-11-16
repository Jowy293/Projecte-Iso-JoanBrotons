#!/bin/bash
# Copia MANUAL de configuracions dels servidors (model "pull": el TrueNAS va a buscar les dades per SSH amb clau)
# Us:  sudo -u backup_user /mnt/Copias/backups/scripts/copia-servidors.sh [opnsense|mikrotik|debian|proxmox|tots]
B=/mnt/Copias/backups; K=$B/.ssh/id_ed25519; D=$(date +%Y%m%d-%H%M)
SSH="ssh -i $K -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o UserKnownHostsFile=$B/.ssh/known_hosts -o ConnectTimeout=8"
ok(){ f=$1; [ -s "$f" ] && echo "OK  $(basename $f)  $(du -h "$f" | cut -f1)  sha256=$(sha256sum "$f" | cut -c1-16)" || { echo "ERROR $f"; rm -f "$f"; }; }
c_opn(){ f=$B/opnsense/config-opnsense11-$D.xml; $SSH root@192.168.11.1 "cat /conf/config.xml" > $f; ok $f; }
c_mk(){  f=$B/mikrotik/mikrotik11-$D.rsc; $SSH backup@192.168.11.2 "/export show-sensitive" | tr -d '\r' > $f; ok $f; }
c_deb(){ f=$B/debian-comms/deb-comms11-etc-$D.tar.gz; $SSH root@192.168.11.3 "tar czf - /etc/nftables.conf /etc/network/interfaces /etc/dnsmasq.d /etc/sysctl.d /etc/ssh/sshd_config /etc/hosts /etc/hostname /etc/NetworkManager/conf.d /etc/systemd/system/httptime.service /etc/systemd/system/httptime.timer /usr/local/sbin/httptime.sh 2>/dev/null" > $f; ok $f; }
c_pve(){ f=$B/proxmox/pve1-config-$D.tar.gz; $SSH root@192.168.11.17 "tar czf - /etc/pve /etc/network/interfaces /etc/hosts /etc/hostname /etc/resolv.conf /etc/apt/sources.list.d 2>/dev/null" > $f; ok $f; }
case "${1:-tots}" in
  opnsense) c_opn;; mikrotik) c_mk;; debian) c_deb;; proxmox) c_pve;;
  tots) c_opn; c_mk; c_deb; c_pve;;
esac
