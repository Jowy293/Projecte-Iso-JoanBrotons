#!/bin/bash
# temps-arrencada.sh "VM" IP_WAN repeticions
# Engega la VM en fred, mesura els segons fins que la seua WAN (en pont amb la xarxa de l'amfitrió) respon al ping
# i l'apaga amb ACPI (apagada neta). Es repeteix N vegades.
export LC_NUMERIC=C
vm=$1; ip=$2; n=${3:-3}
for r in $(seq 1 $n); do
  t0=$(date +%s.%N); VBoxManage startvm "$vm" --type headless >/dev/null
  until ping -c1 -W1 "$ip" >/dev/null 2>&1; do sleep 0.5; done
  t1=$(date +%s.%N); printf "%s · prova %d: %.1f s fins a respondre el ping a %s\n" "$vm" $r "$(echo "$t1-$t0" | bc)" "$ip"
  sleep 20; VBoxManage controlvm "$vm" acpipowerbutton
  until VBoxManage showvminfo "$vm" --machinereadable | grep -q 'VMState="poweroff"'; do sleep 1; done; sleep 3
done
