#!/bin/bash
# Copia MANUAL del client Ubuntu cap al TrueNAS (model "push" per SCP amb clau)
D=$(date +%Y%m%d-%H%M); F=/tmp/ubuntu-client11-$D.tar.gz
tar czf $F --ignore-failed-read \
  /etc/NetworkManager/system-connections /etc/netplan /etc/hosts /etc/hostname \
  /etc/fstab /etc/mdadm/mdadm.conf /etc/ssh/sshd_config /etc/apt/sources.list.d \
  /home/joan11/.bashrc /home/joan11/.profile /home/joan11/Documentos /home/joan11/Escritorio 2>/dev/null
dpkg --get-selections > /tmp/paquets-$D.txt
scp -q -o StrictHostKeyChecking=accept-new $F /tmp/paquets-$D.txt backup_user@192.168.11.5:/mnt/Copias/backups/ubuntu/ \
  && echo "OK $(basename $F) $(du -h $F | cut -f1) + llista de paquets" || echo "ERROR en la copia"
rm -f $F /tmp/paquets-$D.txt
