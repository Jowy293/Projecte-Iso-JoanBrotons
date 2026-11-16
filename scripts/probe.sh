#!/bin/bash
# probe.sh GW : comprova sortida a Internet pel gateway indicat, cada segon, i registra canvis d'estat
GW=$1; ip route replace default via $GW; prev=""
while true; do
  if wget -q -O /dev/null --timeout=2 --tries=1 http://deb.debian.org/debian/; then s=OK; else s=CAIGUT; fi
  [ "$s" != "$prev" ] && echo "$(date +%T.%3N) $GW $s" && prev=$s
  sleep 1
done
