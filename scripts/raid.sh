#!/bin/bash
# Tasca 6 - RAID 0, 1 i 5 amb mdadm (Ubuntu client, discos virtuals de 512 MB)
set -u
echo "### Data: $(date)"; echo "### Discos disponibles"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop
mapfile -t D < <(lsblk -dn -o NAME,SIZE | awk '$2=="512M"{print "/dev/"$1}')
echo "Discos de 512M: ${D[*]}"
[ ${#D[@]} -ge 7 ] || { echo "falten discos"; exit 1; }
for d in "${D[@]}"; do mdadm --zero-superblock "$d" 2>/dev/null; wipefs -aq "$d"; done
echo; echo "### Creacio"
mdadm --create /dev/md0 --run --level=0 --raid-devices=2 ${D[0]} ${D[1]}
mdadm --create /dev/md1 --run --level=1 --raid-devices=2 --metadata=1.2 ${D[2]} ${D[3]}
mdadm --create /dev/md5 --run --level=5 --raid-devices=3 ${D[4]} ${D[5]} ${D[6]}
echo "Esperant sincronitzacio inicial..."; mdadm --wait /dev/md1 /dev/md5 2>/dev/null; sleep 2
cat /proc/mdstat
for m in md0 md1 md5; do mkfs.ext4 -q -L raid_$m /dev/$m; mkdir -p /mnt/$m; mount /dev/$m /mnt/$m; done
echo; echo "### Capacitat util (7 discos x 512M)"; df -h /mnt/md0 /mnt/md1 /mnt/md5
echo; echo "### Rendiment escriptura seqüencial (dd 200M, oflag=direct)"
for m in md0 md1 md5; do echo -n "$m: "; dd if=/dev/zero of=/mnt/$m/test.bin bs=1M count=200 oflag=direct 2>&1 | tail -1; rm -f /mnt/$m/test.bin; done
echo; echo "### Dades de prova amb checksum"
for m in md0 md1 md5; do head -c 50M /dev/urandom > /mnt/$m/dades.bin; sha256sum /mnt/$m/dades.bin | tee /mnt/$m/dades.sha256; done
sync
echo; echo "### PROVA FALLADA RAID1: marquem ${D[3]} com a fallat"
mdadm /dev/md1 --fail ${D[3]}; cat /proc/mdstat | sed -n '/md1/,/^$/p'
echo -n "Integritat amb un disc menys: "; (cd /mnt/md1 && sha256sum -c dades.sha256)
mdadm /dev/md1 --remove ${D[3]}; mdadm --zero-superblock ${D[3]}
t0=$(date +%s); mdadm /dev/md1 --add ${D[3]}; mdadm --wait /dev/md1; t1=$(date +%s)
echo "Reconstruccio RAID1 completada en $((t1-t0)) s"; mdadm --detail /dev/md1 | grep -E 'State :|Active Devices|Failed'
echo; echo "### PROVA FALLADA RAID5: marquem ${D[5]} com a fallat"
mdadm /dev/md5 --fail ${D[5]}; mdadm --detail /dev/md5 | grep -E 'State :|Active Devices|Failed'
echo -n "Integritat en mode degradat: "; (cd /mnt/md5 && sha256sum -c dades.sha256)
mdadm /dev/md5 --remove ${D[5]}; mdadm --zero-superblock ${D[5]}
t0=$(date +%s); mdadm /dev/md5 --add ${D[5]}; mdadm --wait /dev/md5; t1=$(date +%s)
echo "Reconstruccio RAID5 completada en $((t1-t0)) s"; mdadm --detail /dev/md5 | grep -E 'State :|Active Devices|Failed'
echo; echo "### RAID0: no admet --fail (no hi ha redundancia)"
mdadm /dev/md0 --fail ${D[1]} 2>&1 | head -2
echo; echo "### Persistencia"
mdadm --detail --scan | tee /etc/mdadm/mdadm.conf.raid; grep -v '^ARRAY' /etc/mdadm/mdadm.conf > /tmp/m.conf; cat /tmp/m.conf /etc/mdadm/mdadm.conf.raid > /etc/mdadm/mdadm.conf; rm /etc/mdadm/mdadm.conf.raid
for m in md0 md1 md5; do grep -q "/mnt/$m" /etc/fstab || echo "LABEL=raid_$m /mnt/$m ext4 defaults,nofail 0 2" >> /etc/fstab; done
update-initramfs -u >/dev/null 2>&1
echo; echo "### Estat final"; cat /proc/mdstat; mdadm --detail /dev/md5 | head -20
