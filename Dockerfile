FROM centos:7
MAINTAINER isaac@stackhpc.com
RUN yum update -y && \
    yum install -y python-devel python-virtualenv gcc libffi-devel libselinux-python && \
    yum clean all

ENV VIRTUAL_ENV=/venvs/kayobe
RUN python -m virtualenv --python=/usr/bin/python $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ARG kayobe_version='7.0.0'

RUN pip install -U pip && \
    pip install kayobe==$kayobe_version && \
    pip install selinux

COPY . /src/kayobe_config

ENV KAYOBE_CONFIG_ROOT=/src/kayobe_config
ENV KAYOBE_CONFIG_PATH=$KAYOBE_CONFIG_ROOT/etc/kayobe
ENV KOLLA_CONFIG_PATH=$KAYOBE_CONFIG_ROOT/etc/kolla

ENV KOLLA_SOURCE_PATH=/src/kolla-ansible
ENV KOLLA_VENV_PATH=/venvs/kolla-ansible

RUN kayobe control host bootstrap
CMD ["kayobe", "--help"]
