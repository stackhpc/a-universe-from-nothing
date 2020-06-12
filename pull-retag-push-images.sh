#!/bin/bash

set -e

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAYOBE_PATH="$PARENT/../../../"

ARGS="$@"
if [[ -n $1 ]]; then
    KAYOBE_EXTRA_ARGS="-e container_image_regexes=\"$@\""
fi
cd ${KAYOBE_PATH}
source dev/environment-setup.sh
kayobe playbook run ${KAYOBE_CONFIG_PATH}/ansible/pull-retag-push.yml "${KAYOBE_EXTRA_ARGS}"
