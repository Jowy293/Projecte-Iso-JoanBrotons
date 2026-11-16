# 2026-11-16 10:56:11 by RouterOS 7.24.5
# software id = WUF6-U65M
#
/interface ethernet set [ find default-name=ether1 ] disable-running-check=no
/interface ethernet set [ find default-name=ether2 ] disable-running-check=no
/interface list add name=WAN
/interface list add name=LAN
/ip pool add name=dhcp ranges=192.168.11.200-192.168.11.220
/user group add comment="Nomes lectura per a copies" name=copies policy=ssh,ftp,read,test,sensitive,!local,!telnet,!reboot,!write,!policy,!winbox,!password,!web,!sniff,!api,!romon,!rest-api
/interface list member add interface=ether1 list=WAN
/interface list member add interface=ether2 list=LAN
/ip address add address=192.168.11.2/24 interface=ether2 network=192.168.11.0
/ip dhcp-client add interface=ether1 name=client1
/ip dhcp-server add address-pool=dhcp disabled=yes interface=ether2 name=dhcp1
/ip dhcp-server network add address=192.168.11.0/24 dns-server=192.168.11.2 gateway=192.168.11.2 netmask=24
/ip dns set allow-remote-requests=yes
/ip firewall filter add action=accept chain=input comment="IN: establertes" connection-state=established,related
/ip firewall filter add action=drop chain=input comment="IN: invalides" connection-state=invalid
/ip firewall filter add action=accept chain=input comment="IN: ICMP" protocol=icmp
/ip firewall filter add action=accept chain=input comment="IN: tot des de la LAN" in-interface-list=LAN
/ip firewall filter add action=accept chain=input comment="IN: gestio SSH/Winbox des de la xarxa de l aula" dst-port=22,8291 in-interface-list=WAN protocol=tcp src-address=172.16.222.0/24
/ip firewall filter add action=drop chain=input comment="IN: resta WAN bloquejat" in-interface-list=WAN log=yes log-prefix=MK-IN-DROP
/ip firewall filter add action=accept chain=forward comment="FWD: establertes" connection-state=established,related
/ip firewall filter add action=drop chain=forward comment="FWD: invalides" connection-state=invalid
/ip firewall filter add action=drop chain=forward comment="FWD: PROVA connexio bloquejada (Telnet)" dst-port=23 in-interface-list=LAN log=yes log-prefix=MK-BLOQ-TELNET protocol=tcp
/ip firewall filter add action=accept chain=forward comment="FWD: LAN -> Internet" in-interface-list=LAN out-interface-list=WAN
/ip firewall filter add action=drop chain=forward comment="FWD: WAN -> LAN bloquejat" in-interface-list=WAN log=yes log-prefix=MK-FWD-DROP
/ip firewall nat add action=masquerade chain=srcnat comment="NAT LAN->WAN" out-interface-list=WAN
/system clock set time-zone-name=Europe/Madrid
/system identity set name=MikroTik-11

