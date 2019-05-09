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

There two three ways that this workshop can be used.

* `Full deploy <full-deploy>`_
* `A Universe from a Seed <a-universe-from-a-seed>`_

*Full deploy* includes all instructions necessary to go from a plain CentOS 7
cloud image to a running control plane.

*A Universe from a seed* contains all instructions necessary to deploy from
a prepared image containing a seed VM. An image suitable for this can be created
via `Creating a pre-deployed image <creating-a-pre-deployed-image>`_.

Once the control plane has been deployed via one of these methods, see
`next steps <next-steps>`_ for some ideas for what to try next.

.. _a-universe-from-a-seed:

A Universe from a Seed
----------------------

This shows how to deploy a control plane from a VM image that contains a
pre-deployed seed VM. This saves us some time.

Login to your allocated instance as the `lab` user.  The password has been
given by your lab leader.

.. code-block:: console

    ssh lab@<lab-ip-address> -o PreferredAuthentications=password

To prevent interference, change the password.

.. code-block:: console

   passwd

Now we are in, it may be a good idea to start a new screen session 
in case we lose our connection.

.. code-block:: console

   screen -drR

   # Set working directory
   cd ~/kayobe

   # Configure non-persistent networking, if the node has rebooted.
   ./config/src/kayobe-config/configure-local-networking.sh

Make sure that the seed VM (running Bifrost and supporting services)
is present and running.

.. code-block:: console

   # Check if the seed VM is present and running.
   sudo virsh list --all

   # Start up the seed VM if it is shut off.
   sudo virsh start seed

We use the `TENKS project <https://www.stackhpc.com/tenks.html>`_ to model 
some 'bare metal' VMs for the controller and compute node.  Here we set up
our model development environment, alongside the seed VM.

.. code-block:: console

   # NOTE: Make sure to use ./tenks, since just ‘tenks’ will install via PyPI.
   export TENKS_CONFIG_PATH=config/src/kayobe-config/tenks.yml
   ./dev/tenks-deploy.sh ./tenks

   # Activate the Kayobe environment, to allow running commands directly.
   source dev/environment-setup.sh

   # Inspect and provision the overcloud hardware:
   kayobe overcloud inventory discover
   kayobe overcloud hardware inspect
   kayobe overcloud provision

Configure and deploy OpenStack to the control plane
(following `Kayobe host configuration documentation <https://kayobe.readthedocs.io/en/latest/deployment.html#id3>`_):

.. code-block:: console

   kayobe overcloud host configure
   kayobe overcloud container image pull
   kayobe overcloud service deploy
   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   kayobe overcloud post configure

At this point it should be possible to access the Horizon GUI via the lab
server's public IP address, using port 80 (achieved through port
forwarding to the controller VM).  Use the admin credentials from
``OS_USERNAME`` and ``OS_PASSWORD`` to get in.

The following script will register some resources (keys, flavors,
networks, images, etc) in OpenStack to enable booting up a tenant
VM:

.. code-block:: console

   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   ./config/src/kayobe-config/init-runonce.sh

Following the instructions displayed by the above script, boot a VM.
You'll need to have activated the `~/os-venv` virtual environment.

.. code-block:: console

   source ~/os-venv/bin/activate
   openstack server create --image cirros \
             --flavor m1.tiny \
             --key-name mykey \
             --network demo-net demo1

   # Assign a floating IP to the server to make it accessible.
   openstack floating ip create public1
   fip=$(openstack floating ip list -f value -c 'Floating IP Address' --status DOWN | head -n 1)
   openstack server add floating ip demo1 $fip

   # Check SSH access to the VM.
   ssh cirros@$fip

*Note*: when accessing the VNC console of an instance via Horizon,
you will be sent to the internal IP address of the controller,
``192.168.33.2``, which will fail. Choose the console-only display and
replace this IP with the public IP of the lab host.

That's it, you're done!

.. _creating-a-pre-deployed-image:

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

   # Clone the Tenks repository.
   git clone https://git.openstack.org/openstack/tenks.git

   # Shutdown the seed VM.
   sudo virsh shutdown seed

Now take a snapshot of the VM.

.. _full-deploy:

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

.. _next-steps:

Next Steps
==========

Here's some ideas for things to explore with the lab:

* **Access Control Plane Components**: take a deep dive into the internals
  by `Exploring the Deployment`_.
* **Deploy ElasticSearch and Kibana**: see `Enabling Centralised Logging`_
  to get logs aggregated from across our OpenStack control plane.
* **Add another OpenStack service to the configuration**: see 
  `Adding the Barbican service`_ for a worked example of how to deploy 
  a new service.

Exploring the Deployment
------------------------

Once each of the VMs becomes available, they should be accessible
via SSH as the ``centos`` or ``stack`` user at the following IP addresses:

:Seed: ``192.168.33.5``
:Controller: ``192.168.33.3``
:Compute: ``192.168.33.6``

The control plane services are run in Docker containers, so try
using the docker CLI to inspect the system.

.. code-block:: console

    # List containers
    docker ps
    # List images
    docker images
    # List volumes
    docker volume ls
    # Inspect a container
    docker inspect <container name>
    # Execute a process in a container
    docker exec -it <container> <command>

The kolla container configuration is generated under ``/etc/kolla`` on
the seed and overcloud hosts - each container has its own directory
that is bind mounted into the container.

Log files are stored in the ``kolla_logs`` docker volume, which is
mounted at ``/var/log/kolla`` in each container. They can be accessed
on the host at ``/var/lib/docker/volumes/kolla_logs/_data/``.

Exploring Tenks & the Seed
--------------------------

Verify that Tenks has cleated ``controller0`` and ``compute0`` VMs:

.. code-block:: console

    sudo virsh list --all

Verify that `virtualbmc <https://github.com/openstack/virtualbmc>`_ is running:

.. code-block:: console

    ~/tenks-venv/bin/vbmc list
    +-------------+---------+--------------+------+
    | Domain name | Status  | Address      | Port |
    +-------------+---------+--------------+------+
    | compute0    | running | 192.168.33.4 | 6231 |
    | controller0 | running | 192.168.33.4 | 6230 |
    +-------------+---------+--------------+------+

VirtualBMC config is here (on the lab server host):

.. code-block:: console

    /root/.vbmc/controller0/config

Note that the controller and compute node are registered in Ironic, in the bifrost container:

.. code-block:: console

    ssh centos@192.168.33.5
    sudo docker exec -it bifrost_deploy bash
    source env-vars
    ironic node-list                                                           
    The "ironic" CLI is deprecated and will be removed in the S* release. Please use the "openstack baremetal" CLI instead
    +--------------------------------------+-------------+---------------+-------------+--------------------+-------------+
    | UUID                                 | Name        | Instance UUID | Power State | Provisioning State | Maintenance |
    +--------------------------------------+-------------+---------------+-------------+--------------------+-------------+
    | d7184461-ac4b-4b9e-b9ed-329978fc0648 | compute0    | None          | power on    | active             | False       |
    | 1a40de56-be8a-49e2-a903-b408f432ef23 | controller0 | None          | power on    | active             | False       |
    +--------------------------------------+-------------+---------------+-------------+--------------------+-------------+
    exit

Enabling Centralised Logging
----------------------------

In Kolla-Ansible, centralised logging is easily enabled and results in the
deployment of ElasticSearch and Kibana services and configuration to forward
all OpenStack service logging.

To enable the service, one flag must be changed in ``~/kayobe/config/src/kayobe-config/etc/kayobe/kolla.yml``:

.. code-block:: diff

    -#kolla_enable_central_logging:
    +kolla_enable_central_logging: yes

This will install ``elasticsearch`` and ``kibana`` containers, and configure
logging via ``fluentd`` so that logging from all deployed Docker containers will 
be routed to ElasticSearch.

To apply this change:

.. code-block:: console

    kayobe overcloud container image pull
    kayobe overcloud service deploy

As simple as that...

The new containers can be seen running on the controller node:

.. code-block:: console

    $ ssh stack@192.168.33.3 sudo docker ps
    CONTAINER ID        IMAGE                                                                    COMMAND                  CREATED             STATUS              PORTS               NAMES
    304b197f888b        147.75.105.15:4000/kolla/centos-binary-kibana:rocky                      "dumb-init --single-c"   18 minutes ago      Up 18 minutes                           kibana
    9eb0cf47c7f7        147.75.105.15:4000/kolla/centos-binary-elasticsearch:rocky               "dumb-init --single-c"   18 minutes ago      Up 18 minutes                           elasticsearch
    ...

We can see the log indexes in ElasticSearch:

.. code-block:: console

   curl -X GET "192.168.33.3:9200/_cat/indices?v"

To access Kibana, we must first forward connections from our public interface
to the kibana service running on our ``controller0`` VM.

The easiest way to do this is to add Kibana's default port (5601) to our
``configure-local-networking.sh`` script in ``~/kayobe/config/src/kayobe-config/``:

.. code-block:: diff

    --- a/configure-local-networking.sh
    +++ b/configure-local-networking.sh
    @@ -20,7 +20,7 @@ seed_hv_private_ip=$(ip a show dev $iface | grep 'inet ' | awk '{ print $2 }' |
     # Forward the following ports to the controller.
     # 80: Horizon
     # 6080: VNC console
    -forwarded_ports="80 6080"
    +forwarded_ports="80 6080 5601"

Then rerun the script to apply the change:

.. code-block:: console

    config/src/kayobe-config/configure-local-networking.sh

We can now connect to Kibana using our lab host public IP and port 5601.

The username is ``kibana`` and the password we can extract from the
Kolla-Ansible passwords (in production these would be vault-encrypted
but they are not here).

.. code-block:: console

    grep kibana config/src/kayobe-config/etc/kolla/passwords.yml

Once you're in, Kibana needs some further setup which is not automated.
Set the log index to ``flog-*`` and you should be ready to go.

Adding the Barbican service
---------------------------

Barbican is an example of a simple service we can add to our deployment, to
illustrate the process.

References
==========

* Kayobe documentation: https://kayobe.readthedocs.io/en/latest/
* Source: https://git.openstack.org/cgit/openstack/kayobe-config-dev
* Bugs: https://storyboard.openstack.org/#!/project/openstack/kayobe-config-dev
* IRC: #openstack-kayobe
