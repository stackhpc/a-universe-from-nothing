#!/bin/bash

if [[ -z "$KAYOBE_CONFIG_PATH" ]]
then
    echo "Run this script in a Kayobe environment, with KAYOBE_CONFIG_PATH set" >&2
    exit -1
fi

BASE_URL="https://raw.githubusercontent.com/stackhpc/stackhpc-kayobe-config/stackhpc/2024.1/etc/kayobe"

# Download ansible playbooks
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-commands-post.yml $BASE_URL/ansible/cephadm-commands-post.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-commands-pre.yml $BASE_URL/ansible/cephadm-commands-pre.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-crush-rules.yml $BASE_URL/ansible/cephadm-crush-rules.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-deploy.yml $BASE_URL/ansible/cephadm-deploy.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-ec-profiles.yml $BASE_URL/ansible/cephadm-ec-profiles.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-gather-keys.yml $BASE_URL/ansible/cephadm-gather-keys.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-keys.yml $BASE_URL/ansible/cephadm-keys.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm-pools.yml $BASE_URL/ansible/cephadm-pools.yml
curl -o $KAYOBE_CONFIG_PATH/ansible/cephadm.yml $BASE_URL/ansible/cephadm.yml

# Download the cephadm config file
curl -o $KAYOBE_CONFIG_PATH/cephadm.yml https://raw.githubusercontent.com/stackhpc/a-universe-from-nothing/cephadm-role-caracal/etc/kayobe/cephadm.yml.template

echo "Download of cephadm files complete!"
