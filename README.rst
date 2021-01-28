======================================================================================================================
Kayobe Configuration for "A Universe from Nothing: Containerised OpenStack deployment using Kolla, Ansible and Kayobe"
======================================================================================================================

This repository may be used as a workshop to configure, deploy and
get hands-on with OpenStack Kayobe.

It provides a configuration and walkthrough for the `Kayobe
<https://docs.openstack.org/kayobe/latest/>`__ project based on the
configuration provided by the `kayobe-config
<https://opendev.org/openstack/kayobe-config>`__ repository.
It deploys a containerised OpenStack environment using Kolla, Ansible and
Kayobe.

Select the Git branch of this repository for the OpenStack release you
are interested in, and follow the README.

Requirements
============

For this workshop we require the use of a single server, configured as a
*seed hypervisor*. This server should be a bare metal node or VM running
CentOS 8, with the following minimum requirements:

* 32GB RAM
* 80GB disk

We will also need SSH access to the seed hypervisor, and passwordless sudo
configured for the login user.

Exercise
========

On the seed hypervisor we will deploy three VMs:

* 1 seed
* 1 controller
* 1 compute node

The seed runs a standalone Ironic service. The controller and compute node
are 'virtual bare metal' hosts, and we will use the seed to provision them
with an OS. Next we'll deploy OpenStack services on the controller and
compute node.

At the end you'll have a miniature OpenStack cluster that you can use to test
out booting an instance using Nova, access the Horizon dashboard, etc.

Usage
=====

There are four parts to this guide:

* `Preparation`_
* `Deploying a Seed`_
* `A Universe from a Seed`_
* `Next Steps`_

*Preparation* has instructions to prepare the seed hypervisor for the
exercise, and fetching the necessary source code.

*Deploying a Seed* includes all instructions necessary to download and
install the Kayobe prerequisites on a plain CentOS 8 cloud image, including
provisioning and configuration of a seed VM. Optionally, snapshot the
instance after this step to reduce setup time in future.

*A Universe from a Seed* contains all instructions necessary to deploy from
a host running a seed VM. An image suitable for this can be created
via `Optional: Creating a Seed Snapshot`_.

Once the control plane has been deployed see `Next Steps`_ for
some ideas for what to try next.

Preparation
-----------

This shows how to prepare the seed hypervisor for the exercise. It assumes
you have created a seed hypervisor instance fitting the requirements
above and have already logged in (e.g. ``ssh centos@<ip>``).

.. code-block:: console

   # Install git and tmux.
   if $(which dnf 2>/dev/null >/dev/null); then
       sudo dnf -y install git tmux
   else
       sudo apt -y install git tmux
   fi

   # Disable the firewall.
   sudo systemctl is-enabled firewalld && sudo systemctl stop firewalld && sudo systemctl disable firewalld

   # Disable SELinux both immediately and permanently.
   if $(which setenforce 2>/dev/null >/dev/null); then
       sudo setenforce 0
       sudo sed -i 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
   fi

   # Optional: start a new tmux session in case we lose our connection.
   tmux

   # Clone Kayobe.
   git clone https://opendev.org/openstack/kayobe.git -b master
   cd kayobe

   # Clone the Tenks repository.
   git clone https://opendev.org/openstack/tenks.git

   # Clone this Kayobe configuration.
   mkdir -p config/src
   cd config/src/
   git clone https://github.com/stackhpc/a-universe-from-nothing.git kayobe-config -b master

   # Configure host networking (bridge, routes & firewall)
   ./kayobe-config/configure-local-networking.sh

   # Install kayobe.
   cd ~/kayobe
   ./dev/install-dev.sh

Deploying a Seed
----------------

This shows how to create an image suitable for deploying Kayobe.
It assumes you have created a seed hypervisor instance fitting the requirements
above and have already logged in (e.g. ``ssh centos@<ip>``), and performed the
necessary `Preparation`_.

.. code-block:: console

   cd ~/kayobe

   # Deploy hypervisor services.
   ./dev/seed-hypervisor-deploy.sh

   # Deploy a seed VM.
   # FIXME: Will fail first time due to missing bifrost image.
   ./dev/seed-deploy.sh

   # Pull, retag images, then push to our local registry.
   ./config/src/kayobe-config/pull-retag-push-images.sh

   # Deploy a seed VM. Should work this time.
   ./dev/seed-deploy.sh

   # Deploying the seed restarts networking interface,
   # run configure-local-networking.sh again to re-add routes.
   ./config/src/kayobe-config/configure-local-networking.sh

   # Optional: Shutdown the seed VM if creating a seed snapshot.
   sudo virsh shutdown seed

If required, add any additional SSH public keys to /home/centos/.ssh/authorized_keys

Optional: Creating a Seed Snapshot
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If necessary, take a snapshot of the hypervisor instance at this point to speed up this
process in future.

You are now ready to deploy a control plane using this host or snapshot.

A Universe from a Seed
-----------------------------

This shows how to deploy a control plane from a VM image that contains a
pre-deployed seed VM, or a host that has run through the steps in
`Deploying a Seed`.

Having a snapshot image saves us some time if we need to repeat the deployment.
If working from a snapshot, create a new instance with the same dimensions as
the Seed image and log in to it.
Otherwise, continue working with the instance from `Deploying a Seed`_.

.. code-block:: console

   # Optional: start a new tmux session in case we lose our connection.
   tmux

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
   ./dev/tenks-deploy-overcloud.sh ./tenks

   # Activate the Kayobe environment, to allow running commands directly.
   source dev/environment-setup.sh

   # Inspect and provision the overcloud hardware:
   kayobe overcloud inventory discover
   kayobe overcloud hardware inspect
   kayobe overcloud provision

Configure and deploy OpenStack to the control plane
(following `Kayobe host configuration documentation <https://docs.openstack.org/kayobe/latest/deployment.html#id3>`_):

.. code-block:: console

   kayobe overcloud host configure
   kayobe overcloud container image pull
   kayobe overcloud service deploy
   source config/src/kayobe-config/etc/kolla/public-openrc.sh
   kayobe overcloud post configure

At this point it should be possible to access the Horizon GUI via the
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

   # If the ssh command above fails you may need to reconfigure the local
   networking setup again:
   ~/kayobe/config/src/kayobe-config/configure-local-networking.sh

*Note*: when accessing the VNC console of an instance via Horizon,
you will be sent to the internal IP address of the controller,
``192.168.33.2``, which will fail. Choose the console-only display and
replace this IP with the public IP of the hypervisor host.

That's it, you're done!

Next Steps
-----------------------------

Here's some ideas for things to explore with the deployment:

* **Access Control Plane Components**: take a deep dive into the internals
  by `Exploring the Deployment`_.
* **Deploy Elasticsearch and Kibana**: see `Enabling Centralised Logging`_
  to get logs aggregated from across our OpenStack control plane.

Exploring the Deployment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Once each of the VMs becomes available, they should be accessible
via SSH as the ``centos`` or ``stack`` user at the following IP addresses:

===========  ================
Host         IP
===========  ================
seed         ``192.168.33.5``
controller0  ``192.168.33.3``
compute0     ``192.168.33.6``
===========  ================

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
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Verify that Tenks has created ``controller0`` and ``compute0`` VMs:

.. code-block:: console

    sudo virsh list --all

Verify that `virtualbmc <https://opendev.org/openstack/virtualbmc>`_ is running:

.. code-block:: console

    ~/tenks-venv/bin/vbmc list
    +-------------+---------+--------------+------+
    | Domain name | Status  | Address      | Port |
    +-------------+---------+--------------+------+
    | compute0    | running | 192.168.33.4 | 6231 |
    | controller0 | running | 192.168.33.4 | 6230 |
    +-------------+---------+--------------+------+

VirtualBMC config is here (on the VM hypervisor host):

.. code-block:: console

    /root/.vbmc/controller0/config

Note that the controller and compute node are registered in Ironic, in the bifrost container:

.. code-block:: console

    ssh centos@192.168.33.5
    sudo docker exec -it bifrost_deploy bash
    source env-vars
    openstack baremetal node list
    +--------------------------------------+-------------+---------------+-------------+--------------------+-------------+
    | UUID                                 | Name        | Instance UUID | Power State | Provisioning State | Maintenance |
    +--------------------------------------+-------------+---------------+-------------+--------------------+-------------+
    | d7184461-ac4b-4b9e-b9ed-329978fc0648 | compute0    | None          | power on    | active             | False       |
    | 1a40de56-be8a-49e2-a903-b408f432ef23 | controller0 | None          | power on    | active             | False       |
    +--------------------------------------+-------------+---------------+-------------+--------------------+-------------+
    exit

Enabling Centralised Logging
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In Kolla-Ansible, centralised logging is easily enabled and results in the
deployment of Elasticsearch and Kibana services and configuration to forward
all OpenStack service logging.

To enable the service, one flag must be changed in
``~/kayobe/config/src/kayobe-config/etc/kayobe/kolla.yml``:

.. code-block:: diff

    -#kolla_enable_central_logging:
    +kolla_enable_central_logging: yes

This will install ``elasticsearch`` and ``kibana`` containers, and configure
logging via ``fluentd`` so that logging from all deployed Docker containers will
be routed to Elasticsearch.

Before this can be applied, it is necessary to download the missing images to
the seed VM. Pull, retag and push the centralised logging images:

.. code-block:: console

   ~/kayobe/config/src/kayobe-config/pull-retag-push-images.sh kibana elasticsearch

To deploy the logging stack:

.. code-block:: console

    kayobe overcloud container image pull
    kayobe overcloud service deploy

As simple as that...

The new containers can be seen running on the controller node:

.. code-block:: console

    $ ssh stack@192.168.33.3 sudo docker ps
    CONTAINER ID        IMAGE                                                                   COMMAND                  CREATED             STATUS              PORTS               NAMES
    304b197f888b        192.168.33.5:4000/kolla/centos-binary-kibana:master                     "dumb-init --single-c"   18 minutes ago      Up 18 minutes                           kibana
    9eb0cf47c7f7        192.168.33.5:4000/kolla/centos-binary-elasticsearch:master              "dumb-init --single-c"   18 minutes ago      Up 18 minutes                           elasticsearch
    ...

We can see the log indexes in Elasticsearch:

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

We can now connect to Kibana using our hypervisor host public IP and port 5601.

The username is ``kibana`` and the password we can extract from the
Kolla-Ansible passwords (in production these would be vault-encrypted
but they are not here).

.. code-block:: console

    grep kibana config/src/kayobe-config/etc/kolla/passwords.yml

Once you're in, Kibana needs some further setup which is not automated.
Set the log index to ``flog-*`` and you should be ready to go.

Adding the Barbican service
^^^^^^^^^^^^^^^^^^^^^^^^^^^

`Barbican <https://docs.openstack.org/barbican/latest/>`_ is the OpenStack
secret management service. It is an example of a simple service we
can use to illustrate the process of adding new services to our deployment.

As with the Logging service above, enable Barbican by modifying the flag in
``~/kayobe/config/src/kayobe-config/etc/kayobe/kolla.yml`` as follows:

.. code-block:: diff

    -#kolla_enable_barbican:
    +kolla_enable_barbican: yes

This instructs Kolla to install the barbican api, worker & keystone-listener
containers. Pull down barbican images:

.. code-block:: console

   ~/kayobe/config/src/kayobe-config/pull-retag-push-images.sh barbican

To deploy the Barbican service:

.. code-block:: console

    # Activate the venv if not already active
    cd ~/kayobe
    source dev/environment-setup.sh

    kayobe overcloud container image pull
    kayobe overcloud service deploy

Once Barbican has been deployed it can be tested using the barbicanclient
plugin to the OpenStack CLI. This should be installed and tested in the
OpenStack venv:

.. code-block:: console

    # Deactivate existing venv context if necessary
    deactivate

    # Activate the OpenStack venv
    . ~/os-venv/bin/activate

    # Install barbicanclient
    pip install python-barbicanclient -c https://releases.openstack.org/constraints/upper/master

    # Source the OpenStack environment variables
    source ~/kayobe/config/src/kayobe-config/etc/kolla/public-openrc.sh

    # Store a test secret
    openstack secret store --name mysecret --payload foo=bar

    # Copy the 'Secret href' URI for later use
    SECRET_URL=$(openstack secret list --name mysecret -f value --column 'Secret href')

    # Get secret metadata
    openstack secret get ${SECRET_URL}

    # Get secret payload
    openstack secret get ${SECRET_URL} --payload

Congratulations, you have successfully installed Barbican on Kayobe.


References
==========

* Kayobe documentation: https://docs.openstack.org/kayobe/latest/
* Source: https://github.com/stackhpc/a-universe-from-nothing
* Bugs: https://github.com/stackhpc/a-universe-from-nothing/issues
* IRC: #openstack-kolla
