#!/bin/bash
# mesura-host.sh "etiqueta" segons  -> resum de CPU, RAM, swap, disc i xarxa de l'amfitrió + VM enceses
L=$1; T=${2:-60}; N=$((T/2))
echo "===== $L  ($(date '+%F %T'), $T s)"
echo "VM enceses: $(VBoxManage list runningvms | cut -d'"' -f2 | paste -sd, -)"
r0=$(awk '$3=="sda"{print $6}' /proc/diskstats); w0=$(awk '$3=="sda"{print $10}' /proc/diskstats); io0=$(awk '$3=="sda"{print $13}' /proc/diskstats)
n0=$(awk '/eno1/{print $2+$10}' /proc/net/dev)
vmstat -n 2 $N | awk 'NR>3{us+=$13; sy+=$14; id+=$15; wa+=$16; n++; if($13+$14>mx) mx=$13+$14} END{printf "CPU mitjana: us=%.1f%% sy=%.1f%% id=%.1f%% wa=%.1f%% | pic us+sy=%d%%\n",us/n,sy/n,id/n,wa/n,mx}'
r1=$(awk '$3=="sda"{print $6}' /proc/diskstats); w1=$(awk '$3=="sda"{print $10}' /proc/diskstats); io1=$(awk '$3=="sda"{print $13}' /proc/diskstats)
n1=$(awk '/eno1/{print $2+$10}' /proc/net/dev)
echo "Disc sda (USB): lectura $(( (r1-r0)*512/T/1048576 )) MB/s, escriptura $(( (w1-w0)*512/T/1048576 )) MB/s, utilització $(( (io1-io0)/(T*10) ))%"
echo "Xarxa eno1: $(( (n1-n0)/T/1024 )) KB/s"
free -m | awk '/Mem/{printf "RAM: usada %d MB, disponible %d MB de %d MB\n",$3,$7,$2} /Inter|Swap/{printf "Swap usada: %d MB\n",$3}'
awk '/x86_pkg_temp/{f=FILENAME}' /dev/null; for z in /sys/class/thermal/thermal_zone*; do [ "$(cat $z/type)" = x86_pkg_temp ] && echo "Temperatura CPU: $(( $(cat $z/temp)/1000 )) C"; done
