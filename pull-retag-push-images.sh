#!/bin/bash

set -e

PARENT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KAYOBE_PATH="$PARENT/../../../"

if [[ -n $1 ]]; then
    KAYOBE_EXTRA_ARGS="-e container_image_regexes=\"$@\""
fi

# Shift arguments so they are not passed to environment-setup.sh when sourced,
# which would break kayobe-env. See https://unix.stackexchange.com/a/151896 for
# details.
shift $#

cd ${KAYOBE_PATH}
source dev/environment-setup.sh
kayobe playbook run ${KAYOBE_CONFIG_PATH}/ansible/pull-retag-push.yml ${KAYOBE_EXTRA_ARGS:+"$KAYOBE_EXTRA_ARGS"}
