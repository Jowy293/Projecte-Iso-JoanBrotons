#!/bin/bash
# Ubuntu: RAID 1 entre un disc local (sdb) i un LUN iSCSI del TrueNAS (Tasca 6.3)
set -u; TN=192.168.11.5; IQN=iqn.2005-10.org.freenas.ctl:mirror11
echo "### $(date)"; echo "### 1. Alliberem sdb (abans era part del RAID0 md0, ja provat)"
umount /mnt/md0 2>/dev/null; mdadm --stop /dev/md0; sed -i '/md0/d' /etc/fstab; sed -i '/\/dev\/md0/d' /etc/mdadm/mdadm.conf
L=$(lsblk -dn -o NAME,SIZE | awk '$2=="512M"{print "/dev/"$1}' | head -1); mdadm --zero-superblock $L 2>/dev/null; wipefs -aq $L; echo "disc local: $L"
echo "### 2. Iniciador iSCSI"
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq open-iscsi >/dev/null 2>&1 || true
echo "InitiatorName=iqn.2026-11.local.joan11:ubuntu-client11" > /etc/iscsi/initiatorname.iscsi; systemctl restart iscsid
iscsiadm -m discovery -t sendtargets -p $TN
iscsiadm -m node -T $IQN -p $TN --login; sleep 3
iscsiadm -m node -T $IQN -p $TN --op update -n node.startup -v automatic
R=/dev/disk/by-path/$(ls /dev/disk/by-path | grep "ip-$TN.*iscsi.*lun-0$" | head -1); echo "disc remot: $R -> $(readlink -f $R)"
lsblk -o NAME,SIZE,TRAN,MODEL $(readlink -f $R) $L
echo "### 3. RAID1 local + remot (el remot en write-mostly: les lectures es fan del disc local)"
mdadm --create /dev/md10 --run --level=1 --raid-devices=2 --bitmap=internal $L --write-mostly $(readlink -f $R)
mdadm --wait /dev/md10; cat /proc/mdstat | sed -n '/md10/,/^$/p'
mkfs.ext4 -q -L espill_remot /dev/md10; mkdir -p /mnt/espill; mount /dev/md10 /mnt/espill
head -c 30M /dev/urandom > /mnt/espill/dades.bin; (cd /mnt/espill && sha256sum dades.bin > dades.sha256); sync; cat /mnt/espill/dades.sha256
echo "### 4. FALLADA: cau l'equip remot (logout iSCSI = el TrueNAS deixa de ser accessible)"
iscsiadm -m node -T $IQN -p $TN --logout; sleep 3
mdadm --detail /dev/md10 | grep -E "State :|Active|Failed|Working"
echo -n "Lectura de les dades amb només el disc local: "; (cd /mnt/espill && sha256sum -c dades.sha256)
echo "dades noves mentre el remot està caigut" > /mnt/espill/nou.txt; sync
echo "### 5. RECUPERACIÓ: torna l'equip remot"
iscsiadm -m node -T $IQN -p $TN --login; sleep 4; RD=$(readlink -f $R)
mdadm /dev/md10 --remove failed 2>/dev/null; mdadm /dev/md10 --remove detached 2>/dev/null
t0=$(date +%s); mdadm /dev/md10 --re-add $RD 2>/dev/null || mdadm /dev/md10 --add --write-mostly $RD; mdadm --wait /dev/md10; t1=$(date +%s)
echo "Resincronització en $((t1-t0)) s (bitmap intern: només copia els blocs canviats)"
mdadm --detail /dev/md10 | grep -E "State :|Active|Failed|Working|Intent Bitmap"; cat /proc/mdstat | sed -n '/md10/,/^$/p'
mdadm --detail --scan | grep md10 >> /etc/mdadm/mdadm.conf; echo "LABEL=espill_remot /mnt/espill ext4 defaults,nofail,_netdev 0 2" >> /etc/fstab
