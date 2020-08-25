#!/bin/bash

# Cheat script for a full deployment.
# This should be used for testing only.

set -eu

# Install git and tmux.
sudo dnf -y install git tmux

# Disable the firewall.
sudo systemctl is-enabled firewalld && sudo systemctl stop firewalld && sudo systemctl disable firewalld

# Disable SELinux both immediately and permanently.
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

# Clone Kayobe.
[[ -d kayobe ]] || git clone https://git.openstack.org/openstack/kayobe.git -b stable/ussuri
cd kayobe

# Clone the Tenks repository.
[[ -d tenks ]] || git clone https://git.openstack.org/openstack/tenks.git

# Clone this Kayobe configuration.
mkdir -p config/src
cd config/src/
[[ -d kayobe-config ]] || git clone https://github.com/stackhpc/a-universe-from-nothing.git -b stable/ussuri kayobe-config

# Configure host networking (bridge, routes & firewall)
./kayobe-config/configure-local-networking.sh

# Install kayobe.
cd ~/kayobe
./dev/install-dev.sh

# Deploy hypervisor services.
./dev/seed-hypervisor-deploy.sh

# Deploy a seed VM.
# FIXME: Will fail first time due to missing bifrost image.
if ! ./dev/seed-deploy.sh; then
    # Pull, retag images, then push to our local registry.
    ./config/src/kayobe-config/pull-retag-push-images.sh ussuri

    # Deploy a seed VM. Should work this time.
    ./dev/seed-deploy.sh
fi

# Deploying the seed restarts networking interface,
# run configure-local-networking.sh again to re-add routes.
./config/src/kayobe-config/configure-local-networking.sh

# NOTE: Make sure to use ./tenks, since just ‘tenks’ will install via PyPI.
export TENKS_CONFIG_PATH=config/src/kayobe-config/tenks.yml
./dev/tenks-deploy-overcloud.sh ./tenks

# Activate the Kayobe environment, to allow running commands directly.
source dev/environment-setup.sh

set -eu

# Inspect and provision the overcloud hardware:
kayobe overcloud inventory discover
kayobe overcloud hardware inspect
kayobe overcloud provision
kayobe overcloud host configure
kayobe overcloud container image pull
kayobe overcloud service deploy
source config/src/kayobe-config/etc/kolla/public-openrc.sh
kayobe overcloud post configure
kayobe overcloud host command run --command "iptables -P FORWARD ACCEPT" --become --limit controllers
source config/src/kayobe-config/etc/kolla/public-openrc.sh
./config/src/kayobe-config/init-runonce.sh
