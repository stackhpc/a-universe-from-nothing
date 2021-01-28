#!/bin/bash

set -e
set -o pipefail

# This should be run on the seed hypervisor.

source /etc/os-release

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
    sudo dnf -y install iptables
fi

if [[ $ID = "ubuntu" ]]; then
    sudo apt update
    sudo apt -y install ifupdown
fi

# Configure local networking.
# Add a bridge 'braio' for the Kayobe all-in-one cloud network.
if ! sudo ip l show braio >/dev/null 2>&1; then
  sudo ip l add braio type bridge
  if [[ $ID = "ubuntu" ]]; then
    cat << EOF | sudo tee /etc/network/interfaces.d/ifcfg-braio
auto braio
iface braio inet static
address $seed_hv_ip/24
netmask 255.255.255.0
bridge_ports dummy1
EOF
    sudo ifup braio
  else
    sudo ip l set braio up
    sudo ip a add $seed_hv_ip/24 dev braio
  fi
fi
# On CentOS 8, bridges without a port are DOWN, which causes network
# configuration to fail. Add a dummy interface and plug it into the bridge.
if ! sudo ip l show dummy1 >/dev/null 2>&1; then
  sudo ip l add dummy1 type dummy
  if [[ $ID = "ubuntu" ]]; then
    cat << EOF | sudo tee /etc/network/interfaces.d/ifcfg-dummy1
auto dummy1
iface dummy1  inet manual
EOF
    sudo ifup dummy1
  else
    sudo ip l set dummy1 up
    sudo ip l set dummy1 master braio
  fi
fi

# Configure IP routing and NAT to allow the seed VM and overcloud hosts to
# route via this route to the outside world.
sudo iptables -A POSTROUTING -t nat -o $iface -j MASQUERADE
sudo sysctl -w net.ipv4.conf.all.forwarding=1

# Configure port forwarding from the hypervisor to the Horizon GUI on the
# controller.
sudo iptables -A FORWARD -i $iface -o braio -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A FORWARD -i braio -o $iface -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
for port in $forwarded_ports; do
  # Allow new connections.
  sudo iptables -A FORWARD -i $iface -o braio -p tcp --syn --dport $port -m conntrack --ctstate NEW -j ACCEPT
  # Destination NAT.
  sudo iptables -t nat -A PREROUTING -i $iface -p tcp --dport $port -j DNAT --to-destination $controller_vip
  # Source NAT.
  sudo iptables -t nat -A POSTROUTING -o braio -p tcp --dport $port -d $controller_vip -j SNAT --to-source $seed_hv_private_ip
done

# Configure an IP on the 'public' network to allow access to/from the cloud.
if ! sudo ip a show dev braio | grep $public_ip/24 >/dev/null 2>&1; then
  sudo ip a add $public_ip/24 dev braio
fi

echo
echo "NOTE: The network configuration applied by this script is not"
echo "persistent across reboots."
echo "If you reboot the system, please re-run this script."
