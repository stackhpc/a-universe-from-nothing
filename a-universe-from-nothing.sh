#!/bin/bash

# Cheat script for a full deployment.
# This should be used for testing only.

set -eu

# Install git and tmux.
if $(which dnf 2>/dev/null >/dev/null); then
    sudo dnf -y install git tmux
else
    sudo apt update
    sudo apt -y install git tmux
fi

# Disable the firewall.
sudo systemctl is-enabled firewalld && sudo systemctl stop firewalld && sudo systemctl disable firewalld

# Disable SELinux both immediately and permanently.
if $(which setenforce 2>/dev/null >/dev/null); then
    sudo setenforce 0
    sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
fi

# Prevent sudo from performing DNS queries.
echo 'Defaults	!fqdn' | sudo tee /etc/sudoers.d/no-fqdn

# Start at home.
cd

# Clone Beokay.
[[ -d beokay ]] || git clone https://github.com/stackhpc/beokay.git -b master

# Use Beokay to bootstrap your control host.
[[ -d deployment ]] || beokay/beokay.py create --base-path ~/deployment --kayobe-repo https://opendev.org/openstack/kayobe.git --kayobe-branch stable/2023.1 --kayobe-config-repo https://github.com/stackhpc/a-universe-from-nothing.git --kayobe-config-branch stable/2023.1

# Clone the Tenks repository.
cd ~/deployment/src
[[ -d tenks ]] || git clone https://opendev.org/openstack/tenks.git

# Configure host networking (bridge, routes & firewall)
./kayobe-config/configure-local-networking.sh

# Use the kayobe virtual environment, and export kayobe environment variables
source ~/deployment/env-vars.sh

# Configure the seed hypervisor host.
kayobe seed hypervisor host configure

# Provision the seed VM.
kayobe seed vm provision

# Configure the seed host, and deploy a local registry.
kayobe seed host configure

# Pull, retag images, then push to our local registry.
~/deployment/src/kayobe-config/pull-retag-push-images.sh

# Deploy the seed services.
kayobe seed service deploy

# Deploying the seed restarts networking interface,
# run configure-local-networking.sh again to re-add routes.
~/deployment/src/kayobe-config/configure-local-networking.sh

# Set Environment variables for Kayobe dev scripts
export KAYOBE_CONFIG_SOURCE_PATH=~/deployment/src/kayobe-config
export KAYOBE_VENV_PATH=~/deployment/venvs/kayobe
export TENKS_CONFIG_PATH=~/deployment/src/kayobe-config/tenks.yml

# Deploy overcloud using Tenks
~/deployment/src/kayobe/dev/tenks-deploy-overcloud.sh ~/deployment/src/tenks

# Inspect and provision the overcloud hardware:
kayobe overcloud inventory discover
kayobe overcloud hardware inspect
kayobe overcloud introspection data save
kayobe overcloud provision
kayobe overcloud host configure
kayobe overcloud container image pull
kayobe overcloud service deploy
source ~/deployment/src/kayobe-config/etc/kolla/public-openrc.sh
kayobe overcloud post configure
source ~/deployment/src/kayobe-config/etc/kolla/public-openrc.sh
~/deployment/src/kayobe-config/init-runonce.sh
