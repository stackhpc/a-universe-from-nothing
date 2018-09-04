====================
Kayobe Configuration
====================

This repository provides configuration for the `kayobe
<https://github.com/openstack/kayobe>`_ project. It is intended to encourage
version control of site configuration.

Kayobe enables deployment of containerised OpenStack to bare metal.

Containers offer a compelling solution for isolating OpenStack services, but
running the control plane on an orchestrator such as Kubernetes or Docker
Swarm adds significant complexity and operational overheads.

The hosts in an OpenStack control plane must somehow be provisioned, but
deploying a secondary OpenStack cloud to do this seems like overkill.

Kayobe stands on the shoulders of giants:

* OpenStack bifrost discovers and provisions the cloud
* OpenStack kolla builds container images for OpenStack services
* OpenStack kolla-ansible delivers painless deployment and upgrade of
  containerised OpenStack services

To this solid base, kayobe adds:

* Configuration of cloud host OS & flexible networking
* Management of physical network devices
* A friendly openstack-like CLI

All this and more, automated from top to bottom using Ansible.

* Documentation: https://kayobe.readthedocs.io/en/latest/
* Source: https://git.openstack.org/cgit/openstack/kayobe
* Bugs: https://storyboard.openstack.org/#!/project/openstack/kayobe-config
* IRC: #openstack-kayobe
