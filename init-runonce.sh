#!/bin/bash

set -e

if [[ ! -d ~/venvs/os-venv ]]; then
  /usr/bin/python3 -m venv ~/venvs/os-venv
fi
~/venvs/os-venv/bin/pip install -U pip
~/venvs/os-venv/bin/pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/master

parent="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
init_runonce=$parent/../kolla-ansible/tools/init-runonce
if [[ ! -f $init_runonce ]]; then
  echo "Unable to find kolla-ansible repo"
  exit 1
fi

source ~/venvs/os-venv/bin/activate
$init_runonce
