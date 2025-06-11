#!/bin/bash

set -e

if [[ ! -d ~/deployment/venvs/os-venv ]]; then
  /usr/bin/python3 -m venv ~/deployment/venvs/os-venv
fi
~/deployment/venvs/os-venv/bin/pip install -U pip
~/deployment/venvs/os-venv/bin/pip install python-openstackclient -c https://opendev.org/openstack/requirements/raw/branch/unmaintained/2023.1/upper-constraints.txt

parent="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
init_runonce=$parent/../kolla-ansible/tools/init-runonce
if [[ ! -f $init_runonce ]]; then
  echo "Unable to find kolla-ansible repo"
  exit 1
fi

source ~/deployment/venvs/os-venv/bin/activate
$init_runonce
