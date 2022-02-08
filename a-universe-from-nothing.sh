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

# Clone Kayobe.
[[ -d kayobe ]] || git clone https://opendev.org/openstack/kayobe.git -b master
cd kayobe

# Clone the Tenks repository.
[[ -d tenks ]] || git clone https://opendev.org/openstack/tenks.git

# Clone this Kayobe configuration.
mkdir -p config/src
cd config/src/
[[ -d kayobe-config ]] || git clone https://github.com/stackhpc/a-universe-from-nothing.git -b a-multiverse-from-nothing-ceph-tls-master kayobe-config

# Configure host networking (bridge, routes & firewall)
./kayobe-config/configure-local-networking.sh

# Install kayobe.
cd ~/kayobe
./dev/install-dev.sh

# Activate the Kayobe environment, to allow running commands directly.
# NOTE: Virtualenv's activate script references an unbound variable.
set +u
source ~/kayobe-venv/bin/activate
set -u
source config/src/kayobe-config/kayobe-env

# Bootstrap the Ansible control host.
kayobe control host bootstrap

# Configure the seed hypervisor host.
kayobe seed hypervisor host configure

# Provision the seed VM.
kayobe seed vm provision

# Configure the seed host, and deploy a local registry.
kayobe seed host configure

# Pull, retag images, then push to our local registry.
./config/src/kayobe-config/pull-retag-push-images.sh

# Deploy the seed services.
kayobe seed service deploy

# Deploying the seed restarts networking interface,
# run configure-local-networking.sh again to re-add routes.
./config/src/kayobe-config/configure-local-networking.sh

# NOTE: Make sure to use ./tenks, since just ‘tenks’ will install via PyPI.
export TENKS_CONFIG_PATH=config/src/kayobe-config/tenks.yml
./dev/tenks-deploy-overcloud.sh ./tenks

# Generate inventory
kayobe overcloud inventory discover

# Inspect and provision the overcloud hardware:
kayobe overcloud hardware inspect
kayobe overcloud introspection data save
kayobe overcloud provision

kayobe overcloud host configure --skip-tags libvirt-host

# Generate certificates.
kayobe kolla ansible run certificates \
  --kolla-extra kolla_certificates_dir=${KAYOBE_CONFIG_PATH}/kolla/certificates \
  --kolla-extra certificates_generate_libvirt=true

kayobe overcloud host configure --tags libvirt-host --kolla-tags none
kayobe playbook run config/src/kayobe-config/etc/kayobe/ansible/cephadm.yml
kayobe playbook run config/src/kayobe-config/etc/kayobe/ansible/ceph-config.yml
kayobe overcloud container image pull
kayobe overcloud service deploy
source config/src/kayobe-config/etc/kolla/public-openrc.sh
kayobe overcloud post configure
source config/src/kayobe-config/etc/kolla/public-openrc.sh
./config/src/kayobe-config/init-runonce.sh
