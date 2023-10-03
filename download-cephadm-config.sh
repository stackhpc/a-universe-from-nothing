#!/bin/bash

BASE_URL="https://raw.githubusercontent.com/stackhpc/stackhpc-kayobe-config/stackhpc/yoga/etc/kayobe"
DIR1="$HOME/kayobe/config/src/kayobe-config/etc/kayobe/ansible"
DIR2="$HOME/kayobe/config/src/kayobe-config/etc/kayobe"

# Download ansible playbooks
curl -o $DIR1/cephadm-commands-post.yml $BASE_URL/ansible/cephadm-commands-post.yml
curl -o $DIR1/cephadm-commands-pre.yml $BASE_URL/ansible/cephadm-commands-pre.yml
curl -o $DIR1/cephadm-crush-rules.yml $BASE_URL/ansible/cephadm-crush-rules.yml
curl -o $DIR1/cephadm-deploy.yml $BASE_URL/ansible/cephadm-deploy.yml
curl -o $DIR1/cephadm-ec-profiles.yml $BASE_URL/ansible/cephadm-ec-profiles.yml
curl -o $DIR1/cephadm-gather-keys.yml $BASE_URL/ansible/cephadm-gather-keys.yml
curl -o $DIR1/cephadm-keys.yml $BASE_URL/ansible/cephadm-keys.yml
curl -o $DIR1/cephadm-pools.yml $BASE_URL/ansible/cephadm-pools.yml
curl -o $DIR1/cephadm.yml $BASE_URL/ansible/cephadm.yml

# Download the cephadm config file
curl -o $DIR2/cephadm.yml https://raw.githubusercontent.com/stackhpc/a-universe-from-nothing/cephadm-role/etc/kayobe/cephadm.yml.template

echo "Download of cephadm files complete!"
