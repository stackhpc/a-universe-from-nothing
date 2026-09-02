#!/bin/bash

set -e
set -o pipefail

# This should be run on the seed hypervisor.

# IP addresses on the all-in-one Kayobe cloud network.
# These IP addresses map to those statically configured in
# etc/kayobe/network-allocation.yml and etc/kayobe/networks.yml.
controller_vip=192.168.33.2
seed_hv_ip=192.168.33.4

# IP of the seed hypervisor on the OpenStack 'public' network created by init-runonce.sh.
public_ip="10.0.2.1"

# Install iptables.
if $(which dnf >/dev/null 2>&1); then
    sudo dnf -y install iptables kernel-modules-extra
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

# Configure an IP on the 'public' network to allow access to/from the cloud.
if ! sudo ip a show dev braio | grep $public_ip/24 >/dev/null 2>&1; then
  sudo ip a add $public_ip/24 dev braio
fi

echo
echo "NOTE: The network configuration applied by this script is not"
echo "persistent across reboots."
echo "If you reboot the system, please re-run this script."
