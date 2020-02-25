#!/bin/bash

set -e

tag=${1:-stein}
images="kolla/centos-binary-kolla-toolbox
kolla/centos-binary-haproxy
kolla/centos-binary-mariadb
kolla/centos-binary-fluentd
kolla/centos-binary-cron
kolla/centos-binary-keepalived
kolla/centos-binary-neutron-server
kolla/centos-binary-neutron-l3-agent
kolla/centos-binary-neutron-metadata-agent
kolla/centos-binary-neutron-openvswitch-agent
kolla/centos-binary-neutron-dhcp-agent
kolla/centos-binary-glance-api
kolla/centos-binary-nova-compute
kolla/centos-binary-keystone-fernet
kolla/centos-binary-keystone-ssh
kolla/centos-binary-keystone
kolla/centos-binary-nova-api
kolla/centos-binary-nova-consoleauth
kolla/centos-binary-nova-conductor
kolla/centos-binary-nova-ssh
kolla/centos-binary-nova-novncproxy
kolla/centos-binary-nova-scheduler
kolla/centos-binary-placement-api
kolla/centos-binary-openvswitch-vswitchd
kolla/centos-binary-openvswitch-db-server
kolla/centos-binary-nova-libvirt
kolla/centos-binary-memcached
kolla/centos-binary-rabbitmq
kolla/centos-binary-chrony
kolla/centos-binary-heat-api
kolla/centos-binary-heat-api-cfn
kolla/centos-binary-heat-engine
kolla/centos-binary-horizon
kolla/centos-binary-zookeeper
kolla/centos-binary-kafka
kolla/centos-binary-storm
kolla/centos-binary-logstash
kolla/centos-binary-kibana
kolla/centos-binary-elasticsearch
kolla/centos-binary-influxdb
kolla/centos-source-monasca-api
kolla/centos-source-monasca-log-api
kolla/centos-source-monasca-notification
kolla/centos-source-monasca-persister
kolla/centos-source-monasca-agent
kolla/centos-source-monasca-thresh
kolla/centos-source-monasca-grafana
kolla/centos-source-bifrost-deploy"
registry=192.168.33.5:4000

for image in $images; do
    ssh stack@192.168.33.5 sudo docker pull $image:$tag
    ssh stack@192.168.33.5 sudo docker tag $image:$tag $registry/$image:$tag
    ssh stack@192.168.33.5 sudo docker push $registry/$image:$tag
done
