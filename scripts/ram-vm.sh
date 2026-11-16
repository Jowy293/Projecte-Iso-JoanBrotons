#!/bin/bash
# ram-vm.sh -> per cada VM encesa: RAM assignada i RAM que ocupa realment a l'amfitrió (RSS del procés VBoxHeadless)
printf "%-38s %10s %12s\n" "VM" "Assignada" "Ocupada (RSS)"
ta=0; tr=0
while read -r pid rss rest; do
  vm=$(echo "$rest" | sed -E 's/.*--comment (.*) --startvm.*/\1/')
  a=$(VBoxManage showvminfo "$vm" --machinereadable | awk -F= '/^memory=/{print $2}')
  r=$((rss/1024)); ta=$((ta+a)); tr=$((tr+r))
  printf "%-38s %7d MB %9d MB\n" "$vm" "$a" "$r"
done < <(ps -eo pid=,rss=,args= | grep "[V]BoxHeadless --comment")
printf "%-38s %7d MB %9d MB\n" "TOTAL" "$ta" "$tr"
free -m | awk '/Mem/{printf "Amfitrió: RAM usada %d MB, disponible %d MB de %d MB\n",$3,$7,$2} /Inter|Swap/{printf "Swap usada: %d MB\n",$3}'
