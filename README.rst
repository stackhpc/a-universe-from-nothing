======================================================================================================================
Kayobe Configuration for "A Universe from Nothing: Containerised OpenStack deployment using Kolla, Ansible and Kayobe"
======================================================================================================================

This repository provides configuration for the `Kayobe
<https://kayobe.readthedocs.io/en/latest>`__ project. It is based on the
configuration provided by the `kayobe-config
<https://git.openstack.org/cgit/openstack/kayobe-config>`__ repository, and
provides a set of configuration suitable for a workshop on deploying
containerised OpenStack using Kolla, Ansible and Kayobe.

Requirements
============

The configuration includes:

* 1 seed hypervisor (localhost)
* 1 seed
* 1 controller
* 1 compute node

The latter three hosts are run as VMs on the seed hypervisor.  This should be
a bare metal node or VM running CentOS 7, with the following minimum
requirements:

* 32GB RAM
* 40GB disk

Usage
=====

A Universe from a Seed
----------------------

This shows how to deploy a control plane from a VM image that contains a
pre-deployed seed VM. This saves us some time.

.. code-block:: console

   # Optional: start a new screen session in case we lose our connection.
   screen -drR

   # Configure non-persistent networking.
   ./kayobe-config/configure-local-networking.sh

   # Start up the seed VM.
   sudo virsh start seed

   # Create some 'bare metal' VMs for the controller and compute node.
   # NOTE: Make sure to use ./tenks, since just ‘tenks’ will install via PyPI.
   export TENKS_CONFIG_PATH=config/src/kayobe-config/tenks.yml
   ./dev/tenks-deploy.sh ./tenks

   # Activate the Kayobe environment, to allow running commands directly.
   source dev/environment-setup.sh

   # Inspect and provision the overcloud hardware:
   kayobe overcloud inventory discover
   kayobe overcloud hardware inspect
   kayobe overcloud provision

   # Deploy the control plane:
   # (following https://kayobe.readthedocs.io/en/latest/deployment.html#id3)
   kayobe overcloud host configure
   kayobe overcloud container image pull
   kayobe overcloud service deploy
   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   kayobe overcloud post configure

   # At this point it should be possible to access the Horizon GUI via the seed
   # hypervisor's floating IP address, using port 80 (achieved through port
   # forwarding).

   # Note that when accessing the VNC console of an instance via Horizon, you
   # will be sent to the internal IP address of the controller, 192.168.33.2,
   # which will fail. Replace this with the floating IP of the seed hypervisor
   # VM.

   # The following script will register some resources in OpenStack to enable
   # booting up a tenant VM.
   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   ./config/src/kayobe-config/init-runonce.sh

   # Following the instructions displayed by the above script, boot a VM.
   # You'll need to have activated the ~/os-venv virtual environment.
   source ~/os-venv/bin/activate
   openstack server create --image cirros --flavor m1.tiny --key-name mykey --network demo-net demo1

   # Assign a floating IP to the server to make it accessible.
   openstack floating ip create public1
   fip=$(openstack floating ip list -f value -c 'Floating IP Address' --status DOWN | head -n 1)
   openstack server add floating ip demo1 $fip

   # Check SSH access to the VM.
   ssh cirros@$fip

Creating a pre-deployed image
-----------------------------

This shows how to create an image suitable for the above exercise.

.. code-block:: console

   # Install git and screen.
   sudo yum -y install git screen

   # Optional: start a new screen session in case we lose our connection.
   screen -drR

   # Clone Kayobe.
   git clone https://git.openstack.org/openstack/kayobe.git -b stable/rocky
   cd kayobe

   # Clone this Kayobe configuration.
   mkdir -p config/src
   cd config/src/
   git clone https://github.com/stackhpc/a-universe-from-nothing.git -b packet kayobe-config

   ./kayobe-config/configure-local-networking.sh

   # Install kayobe.
   cd ~/kayobe
   ./dev/install.sh

   # Deploy hypervisor services.
   ./dev/seed-hypervisor-deploy.sh

   # Deploy a seed VM.
   # FIXME: Will fail first time due to missing bifrost image.
   ./dev/seed-deploy.sh

   # Pull, retag images, then push to our local registry.
   ./config/src/kayobe-config/pull-retag-push-images.sh

   # Deploy a seed VM. Should work this time.
   ./dev/seed-deploy.sh

   # FIXME: There is an issue with Bifrost which does not restrict the version
   # of proliantutils it installs.
   ssh stack@192.168.33.5 sudo docker exec bifrost_deploy pip install proliantutils==2.7.0
   ssh stack@192.168.33.5 sudo docker exec bifrost_deploy systemctl restart ironic-conductor

   # Clone the Tenks repository.
   git clone https://git.openstack.org/openstack/tenks.git

   # Shutdown the seed VM.
   sudo virsh shutdown seed

Now take a snapshot of the VM.

Full Deploy
-----------

This shows how to deploy a universe from scratch using a plain CentOS 7 image.

.. code-block:: console

   # Install git and screen.
   sudo yum -y install git screen

   # Optional: start a new screen session in case we lose our connection.
   screen -drR

   # Clone Kayobe.
   git clone https://git.openstack.org/openstack/kayobe.git -b stable/rocky
   cd kayobe

   # Clone this Kayobe configuration.
   mkdir -p config/src
   cd config/src/
   git clone https://github.com/stackhpc/a-universe-from-nothing.git kayobe-config

   ./kayobe-config/configure-local-networking.sh

   # Install kayobe.
   cd ~/kayobe
   ./dev/install.sh

   # Deploy hypervisor services.
   ./dev/seed-hypervisor-deploy.sh

   # Deploy a seed VM.
   # FIXME: Will fail first time due to missing bifrost image.
   ./dev/seed-deploy.sh

   # Pull, retag images, then push to our local registry.
   ./config/src/kayobe-config/pull-retag-push-images.sh

   # Deploy a seed VM. Should work this time.
   ./dev/seed-deploy.sh

   # FIXME: There is an issue with Bifrost which does not restrict the version
   # of proliantutils it installs.
   ssh stack@192.168.33.5 sudo docker exec bifrost_deploy pip install proliantutils==2.7.0
   ssh stack@192.168.33.5 sudo docker exec bifrost_deploy systemctl restart ironic-conductor

   # Clone the Tenks repository, deploy some VMs for the controller and compute node.
   git clone https://git.openstack.org/openstack/tenks.git
   # NOTE: Make sure to use ./tenks, since just ‘tenks’ will install via PyPI.
   export TENKS_CONFIG_PATH=config/src/kayobe-config/tenks.yml
   ./dev/tenks-deploy.sh ./tenks

   # Activate the Kayobe environment, to allow running commands directly.
   source dev/environment-setup.sh

   # Inspect and provision the overcloud hardware:
   kayobe overcloud inventory discover
   kayobe overcloud hardware inspect
   kayobe overcloud provision

   # Deploy the control plane:
   # (following https://kayobe.readthedocs.io/en/latest/deployment.html#id3)
   kayobe overcloud host configure
   kayobe overcloud container image pull
   kayobe overcloud service deploy
   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   kayobe overcloud post configure

   # At this point it should be possible to access the Horizon GUI via the seed
   # hypervisor's floating IP address, using port 80 (achieved through port
   # forwarding).

   # Note that when accessing the VNC console of an instance via Horizon, you
   # will be sent to the internal IP address of the controller, 192.168.33.2,
   # which will fail. Replace this with the floating IP of the seed hypervisor
   # VM.

   # The following script will register some resources in OpenStack to enable
   # booting up a tenant VM.
   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   ./config/src/kayobe-config/init-runonce.sh

   # Following the instructions displayed by the above script, boot a VM.
   # You'll need to have activated the ~/os-venv virtual environment.
   source ~/os-venv/bin/activate
   openstack server create --image cirros --flavor m1.tiny --key-name mykey --network demo-net demo1

   # Assign a floating IP to the server to make it accessible.
   openstack floating ip create public1
   fip=$(openstack floating ip list -f value -c 'Floating IP Address' --status DOWN | head -n 1)
   openstack server add floating ip demo1 $fip

   # Check SSH access to the VM.
   ssh cirros@$fip

References
==========

* Kayobe documentation: https://kayobe.readthedocs.io/en/latest/
* Source: https://git.openstack.org/cgit/openstack/kayobe-config-dev
* Bugs: https://storyboard.openstack.org/#!/project/openstack/kayobe-config-dev
* IRC: #openstack-kayobe
