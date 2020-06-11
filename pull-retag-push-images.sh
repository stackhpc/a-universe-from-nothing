#!/bin/bash

set -e

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAYOBE_PATH="$PARENT/../../../"

cd ${KAYOBE_PATH}
source dev/environment-setup.sh
kayobe playbook run ${KAYOBE_CONFIG_PATH}/ansible/pull-retag-push.yml "$@"
