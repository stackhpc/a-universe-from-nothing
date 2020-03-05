#!/bin/sh

set -x

if [ -d /secrets/.ssh ]; then
    cp -R /secrets/.ssh /$KAYOBE_USER/.ssh
    chmod 700 /$KAYOBE_USER/.ssh
    if [ -f /$KAYOBE_USER/.ssh/id_rsa.pub ]; then
	chmod 644 /$KAYOBE_USER/.ssh/id_rsa.pub
    fi
    if [ -f /$KAYOBE_USER/.ssh/id_rsa ]; then
	chmod 600 /$KAYOBE_USER/.ssh/id_rsa
    fi
    if [ -f /$KAYOBE_USER/.ssh/config ]; then
	chmod 600 /$KAYOBE_USER/.ssh/config
    fi
fi

exec "$@"
