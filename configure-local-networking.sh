#!/bin/bash

set -e
set -o pipefail

# This should be run on the seed hypervisor.

# IP addresses on the all-in-one Kayobe cloud network.
# These IP addresses map to those statically configured in
# etc/kayobe/network-allocation.yml and etc/kayobe/networks.yml.
controller_vip=192.168.33.2
seed_hv_ip=192.168.33.4
seed_vm_ip=192.168.33.5

iface=$(ip route | awk '$1 == "default" {print $5; exit}')

# Private IP address by which the seed hypervisor is accessible in the cloud
# hosting the VM.
seed_hv_private_ip=$(ip a show dev $iface | awk '$1 == "inet" { gsub(/\/[0-9]*/,"",$2); print $2; exit }')

# Forward the following ports to the controller.
# 80: Horizon
# 6080: VNC console
forwarded_ports="80 6080"

# IP of the seed hypervisor on the OpenStack 'public' network created by init-runonce.sh.
public_ip="10.0.2.1"

# Install iptables.
if $(which dnf >/dev/null 2>&1); then
    sudo dnf -y install nftables
fi

if $(which apt >/dev/null 2>&1); then
    sudo apt update
    sudo apt -y install iptables
fi

# Configure local networking.
# Add a bridge 'braio' for the Kayobe all-in-one cloud network.
if ! sudo ip l show braio >/dev/null 2>&1; then
  sudo ip l add braio type bridge
  sudo ip l set braio up
  sudo ip a add $seed_hv_ip/24 dev braio
fi
# On CentOS 8, bridges without a port are DOWN, which causes network
# configuration to fail. Add a dummy interface and plug it into the bridge.
if ! sudo ip l show dummy1 >/dev/null 2>&1; then
  sudo ip l add dummy1 type dummy
  sudo ip l set dummy1 up
  sudo ip l set dummy1 master braio
fi

sudo sysctl -w net.ipv4.conf.all.forwarding=1

sudo nft add rule ip nat postrouting oif "$iface" masquerade

# Create tables if not existing
sudo nft add table inet filter 2>/dev/null
sudo nft add table ip nat 2>/dev/null

# Create chains if not existing
sudo nft add chain inet filter forward '{ type filter hook forward priority 0; }' 2>/dev/null
sudo nft add chain ip nat prerouting '{ type nat hook prerouting priority -100; }' 2>/dev/null
sudo nft add chain ip nat postrouting '{ type nat hook postrouting priority 100; }' 2>/dev/null

sudo nft add rule ip nat postrouting oif "$iface" masquerade

# ----- FILTER RULES -----

# Allow established/related traffic: $iface → braio
sudo nft add rule inet filter forward iif "$iface" oif braio ct state established,related accept

# Allow established/related traffic: braio → $iface
sudo nft add rule inet filter forward iif braio oif "$iface" ct state established,related accept

# ----- PORT-SPECIFIC RULES -----

for port in $forwarded_ports; do
  # Allow NEW TCP connections from $iface → braio on this port
  sudo nft add rule inet filter forward \
       iif "$iface" oif braio tcp dport "$port" ct state new accept

  # DNAT: incoming traffic on $iface to controller VIP
  sudo nft add rule ip nat prerouting \
       iif "$iface" tcp dport "$port" dnat to "$controller_vip"

  # SNAT: return traffic going to controller VIP on braio
  sudo nft add rule ip nat postrouting \
       oif braio ip daddr "$controller_vip" tcp dport "$port" snat to "$seed_hv_private_ip"
done

# Configure an IP on the 'public' network to allow access to/from the cloud.
if ! sudo ip a show dev braio | grep $public_ip/24 >/dev/null 2>&1; then
  sudo ip a add $public_ip/24 dev braio
fi

echo
echo "NOTE: The network configuration applied by this script is not"
echo "persistent across reboots."
echo "If you reboot the system, please re-run this script."
