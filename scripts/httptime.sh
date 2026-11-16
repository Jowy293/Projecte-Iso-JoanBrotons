#!/bin/sh
# NTP (UDP/123) esta bloquejat a la xarxa de l'aula: sincronitzem l'hora amb la capçalera Date d'HTTP
D=$(curl -sI --max-time 5 http://deb.debian.org | sed -n 's/^[Dd]ate: //p' | tr -d '\r')
[ -n "$D" ] && date -s "$D" >/dev/null && echo "hora sincronitzada: $(date)"
