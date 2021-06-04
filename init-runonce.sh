#!/bin/bash

set -e

if [[ ! -d ~/os-venv ]]; then
  virtualenv ~/os-venv
fi
~/os-venv/bin/pip install -U pip
~/os-venv/bin/pip install python-openstackclient -c https://releases.openstack.org/constraints/upper/wallaby

parent="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
init_runonce=$parent/../kolla-ansible/tools/init-runonce
if [[ ! -f $init_runonce ]]; then
  echo "Unable to find kolla-ansible repo"
  exit 1
fi

source ~/os-venv/bin/activate
$init_runonce
