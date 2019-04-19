#!/bin/bash

CONTAINER=$1
lxc version | grep "Server version" >/dev/null 2>&1

# NOTE: configure lxdbr0
echo "Configure lxdbr0"
lxc network set lxdbr0 ipv4.address 10.75.59.1/24
lxc network set lxdbr0 ipv4.dhcp.ranges 10.75.59.2-10.75.59.50

# Create container
echo "Creating container $CONTAINER"
lxc profile create maas-profile 2> /dev/null
lxc profile edit maas-profile < maas-profile
lxc launch ubuntu:18.04 $CONTAINER -p maas-profile -s default

echo "Sleeping to wait for IP"
sleep 10

# Setup LXD forward for pxe requests
IPADDRESS=$(lxc info $CONTAINER | awk -F"[: \t]+" '/br0:.*inet[^6]/ {print $4}')
if [[ $IPADDRESS =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	echo "Setting up pxe redirect for IP $IPADDRESS"
	#lxc network set lxdbr0 raw.dnsmasq dhcp-boot=pxelinux.0,$CONTAINER,$IPADDRESS
	#echo -e "auth-zone=lxd\ndns-loop-detect" | lxc network set lxdbr0 raw.dnsmasq -
	echo -e "auth-zone=lxd\ndns-loop-detect\ndhcp-boot=pxelinux.0,$CONTAINER,$IPADDRESS" | lxc network set lxdbr0 raw.dnsmasq -
	echo "MAAS will become available at: http://$IPADDRESS:5240/MAAS with user/password admin/admin"
else
	echo "Abort. This is not a valid ip address: $IPADDRESS"
fi
