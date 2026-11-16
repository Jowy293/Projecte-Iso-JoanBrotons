#!/bin/bash
# t4-connectivitat.sh — recull interfícies, rutes, pings i traceroute de les VM Linux/BSD de la LAN 192.168.11.0/24
# Ús: PW=<contrasenya> ./t4-connectivitat.sh > evidencies/t4-connectivitat.txt   (salt per la WAN del Debian)
J="-J administrador11@172.16.222.195"
X="$(dirname "$0")/../../bin/sshx.py"
LAN="1 2 3 5 10 17 20 25"
PINGS='for h in '"$LAN"'; do printf "  192.168.11.%-3s " $h; if ping -c2 -W1 192.168.11.$h >/dev/null 2>&1; then echo OK; else echo "SENSE RESPOSTA"; fi; done'
run(){ echo; echo "================ $1 ================"; timeout 120 python3 "$X" "$2" "$PW" "$3" $J 2>&1 | sed 's/^/  /'; }
echo "# Tasca 4 · Evidències de connectivitat — $(date '+%d/%m/%Y %H:%M')"
run "Ubuntu client (.25)" joan11@192.168.11.25 "hostname; echo '-- interfícies'; ip -br a; echo '-- rutes'; ip r; echo '-- DNS'; resolvectl dns 2>/dev/null | grep -v ': *$'; echo '-- ping a la LAN'; $PINGS; echo '-- eixida a Internet'; getent hosts www.gva.es; curl -s -o /dev/null -w 'HTTPS www.gva.es -> codi %{http_code} en %{time_total}s\n' https://www.gva.es; echo '-- traceroute (TCP 443) a www.gva.es'; tracepath -n -m 8 www.gva.es 2>&1 | head -12"
run "Debian nftables (.3)" administrador11@192.168.11.3 "hostname; ip -br a; ip r; $PINGS; tracepath -n -m 6 www.gva.es 2>&1 | head -8"
run "OPNsense (.1)" root@192.168.11.1 "/bin/sh -c 'hostname; ifconfig -a inet | grep -E \"flags|inet \"; netstat -rn -f inet | head -14; $PINGS; echo -- traceroute; traceroute -n -m 6 -w 1 193.145.206.124 2>&1'"
run "MikroTik (.2)" administrador11@192.168.11.2 "/system identity print; /ip address print; /ip route print; :foreach h in={1;3;5;10;17;20;25} do={:put (\"192.168.11.\" . \$h . \" -> \" . [/ping (\"192.168.11.\" . \$h) count=2]  . \"/2 respostes\")}"
run "Proxmox (.17)" root@192.168.11.17 "hostname; ip -br a; ip r; $PINGS"
run "TrueNAS (.5)" truenas_admin@192.168.11.5 "hostname; ip -br a; ip r; $PINGS"
