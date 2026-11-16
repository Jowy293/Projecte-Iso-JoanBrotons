#!/bin/bash
# TrueNAS: exporta un zvol de 600 MB per iSCSI per a l'espill remot (Tasca 6.3)
set -e; M=midclt
zfs list Copias/iscsi-mirror11 >/dev/null 2>&1 || $M call pool.dataset.create '{"name":"Copias/iscsi-mirror11","type":"VOLUME","volsize":629145600,"volblocksize":"16K","comments":"Meitat remota del RAID1 entre equips (T6.3)"}' >/dev/null
P=$($M call iscsi.portal.query | jq '.[0].id // empty'); [ -n "$P" ] || P=$($M call iscsi.portal.create '{"listen":[{"ip":"0.0.0.0"}],"comment":"LAN"}' | jq .id)
I=$($M call iscsi.initiator.query | jq '.[0].id // empty'); [ -n "$I" ] || I=$($M call iscsi.initiator.create '{"initiators":["iqn.2026-11.local.joan11:ubuntu-client11"],"comment":"Ubuntu client"}' | jq .id)
T=$($M call iscsi.target.query '[["name","=","mirror11"]]' | jq '.[0].id // empty'); [ -n "$T" ] || T=$($M call iscsi.target.create "{\"name\":\"mirror11\",\"groups\":[{\"portal\":$P,\"initiator\":$I,\"authmethod\":\"NONE\"}]}" | jq .id)
E=$($M call iscsi.extent.query '[["name","=","mirror11"]]' | jq '.[0].id // empty'); [ -n "$E" ] || E=$($M call iscsi.extent.create '{"name":"mirror11","type":"DISK","disk":"zvol/Copias/iscsi-mirror11"}' | jq .id)
[ "$($M call iscsi.targetextent.query "[[\"target\",\"=\",$T]]" | jq length)" -gt 0 ] || $M call iscsi.targetextent.create "{\"target\":$T,\"extent\":$E,\"lunid\":0}" >/dev/null
$M call service.update iscsitarget '{"enable":true}' >/dev/null; $M call service.control START iscsitarget >/dev/null || true
echo "basename: $($M call iscsi.global.config | jq -r .basename)"; echo "target: mirror11 portal=$P initiator=$I extent=$E"
$M call service.query '[["service","=","iscsitarget"]]' | jq -c '.[0]|{state,enable}'; zfs list -o name,volsize,used Copias/iscsi-mirror11
