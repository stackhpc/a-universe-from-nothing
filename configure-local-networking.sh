#!/bin/bash

set -e

# This should be run on the seed hypervisor.

# IP addresses on the all-in-one Kayobe cloud network.
# These IP addresses map to those statically configured in
# etc/kayobe/network-allocation.yml and etc/kayobe/networks.yml.
controller_vip=192.168.33.2
seed_hv_ip=192.168.33.4
seed_vm_ip=192.168.33.5

iface=$(route | grep '^default' | grep -o '[^ ]*$')

# Private IP address by which the seed hypervisor is accessible in the cloud
# hosting the VM.
seed_hv_private_ip=$(ip a show dev $iface | grep 'inet ' | awk '{ print $2 }' | sed 's/\/.*//g' | head -n1)

# Forward the following ports to the controller.
# 80: Horizon
# 6080: VNC console
forwarded_ports="80 6080"

# IP of the seed hypervisor on the OpenStack 'public' network created by init-runonce.sh.
public_ip="10.0.2.1"

# Configure local networking.
# Add a bridge 'braio' for the Kayobe all-in-one cloud network.
if ! sudo ip l show braio 2>&1 >/dev/null; then
  sudo ip l add braio type bridge
  sudo ip l set braio up
  sudo ip a add $seed_hv_ip/24 dev braio
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
sudo ip a add $public_ip/24 dev braio

echo
echo "NOTE: The network configuration applied by this script is not"
echo "persistent across reboots."
echo "If you reboot the system, please re-run this script."
