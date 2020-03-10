#!/bin/sh

set -x

if [ -d /secrets/.ssh ]; then
    cp -R /secrets/.ssh /stack/.ssh
    chmod 700 /stack/.ssh
    if [ -f /stack/.ssh/id_rsa.pub ]; then
	chmod 644 /stack/.ssh/id_rsa.pub
    fi
    if [ -f /stack/.ssh/id_rsa ]; then
	chmod 600 /stack/.ssh/id_rsa
    fi
    if [ -f /stack/.ssh/config ]; then
	chmod 600 /stack/.ssh/config
    fi
fi

if [ -d /secrets/vault.pass ]; then
    export KAYOBE_VAULT_PASSWORD=$(cat /secrets/vault.pass)
fi
exec "$@"
