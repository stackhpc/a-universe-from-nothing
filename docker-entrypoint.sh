#!/bin/sh

set -x

cp -R /secrets/.ssh /$KAYOBE_USER/.ssh
chmod 700 /$KAYOBE_USER/.ssh
chmod 644 /$KAYOBE_USER/.ssh/id_rsa.pub
chmod 600 /$KAYOBE_USER/.ssh/id_rsa

exec "$@"
