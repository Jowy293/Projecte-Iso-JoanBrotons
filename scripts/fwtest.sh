#!/bin/bash
# Prova connexio permesa (HTTP 80) i bloquejada (Telnet 23) a traves de cada passarel·la
for gw in 192.168.11.1 192.168.11.2 192.168.11.3; do
  ip route replace default via $gw
  echo "================ Passarel·la $gw  ($(date '+%F %T'))"
  ip route show default
  echo "--- tracepath (primers salts)"; tracepath -n -m 3 1.1.1.1 2>&1 | head -5
  echo -n "--- PERMESA  HTTP deb.debian.org:80 -> "; (s=$(date +%s.%N); wget -q -O /dev/null --timeout=8 http://deb.debian.org/debian/ && echo "OK (HTTP 200) en $(echo "$(date +%s.%N) - $s" | bc 2>/dev/null || echo ?)s") || echo "FALLA"
  echo -n "--- BLOQUEJADA TCP 1.1.1.1:23 (telnet) -> "; timeout 5 bash -c 'echo > /dev/tcp/1.1.1.1/23' 2>/dev/null && echo "OBERTA (no bloquejada!)" || echo "SENSE RESPOSTA / BLOQUEJADA"
done
ip route replace default via 192.168.11.1
echo "== Restaurada passarel·la per defecte:"; ip route show default
