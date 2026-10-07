#!/bin/sh 

# OpenWRT configuration for the SmartV lab 

  

# Hostname and timezone 

uci set system.@system[0].hostname='openwrt-gw' 

uci set system.@system[0].zonename='Australia/Sydney' 

uci set system.@system[0].timezone='AEST-10AEDT,M10.1.0,M4.1.0/3' 

uci set system.ntp.enable_server='1' 

uci commit system 

  

# LAN address 

uci set network.lan.ipaddr='192.168.10.254' 

uci set network.lan.netmask='255.255.255.0' 

uci commit network 

  

# DHCP pool: 192.168.10.100 to 192.168.10.249 

uci set dhcp.lan.start='100' 

uci set dhcp.lan.limit='150' 

uci set dhcp.lan.leasetime='12h' 

  

# Local domain 

uci set dhcp.@dnsmasq[0].domain='smartv.lab' 

uci set dhcp.@dnsmasq[0].local='/smartv.lab/' 

uci set dhcp.@dnsmasq[0].expandhosts='1' 

  

# DNS records (removes old ones first, so this is safe to re-run) 

while uci -q delete dhcp.@domain[0]; do :; done 

uci add dhcp domain 

uci set dhcp.@domain[-1].name='esxi-1.smartv.lab' 

uci set dhcp.@domain[-1].ip='192.168.10.11' 

uci add dhcp domain 

uci set dhcp.@domain[-1].name='esxi-2.smartv.lab' 

uci set dhcp.@domain[-1].ip='192.168.10.12' 

uci add dhcp domain 

uci set dhcp.@domain[-1].name='esxi-3.smartv.lab' 

uci set dhcp.@domain[-1].ip='192.168.10.13' 

uci add dhcp domain 

uci set dhcp.@domain[-1].name='vcenter.smartv.lab' 

uci set dhcp.@domain[-1].ip='192.168.10.20' 

uci add dhcp domain 

uci set dhcp.@domain[-1].name='iscsi.smartv.lab' 

uci set dhcp.@domain[-1].ip='192.168.10.30' 

uci commit dhcp 

  

# Apply 

/etc/init.d/system reload 

/etc/init.d/sysntpd restart 

/etc/init.d/dnsmasq restart 

/etc/init.d/network restart 

  

echo "Done. LAN is now 192.168.10.254" 
