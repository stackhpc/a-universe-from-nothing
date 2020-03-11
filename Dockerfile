FROM centos:7
MAINTAINER isaac@stackhpc.com
RUN yum update -y && \
    yum install -y python-devel python-virtualenv gcc libffi-devel libselinux-python git sudo && \
    yum clean all

ENV KAYOBE_USER=stack
ARG KAYOBE_USER_UID=1000
ARG KAYOBE_USER_GID=1000

RUN groupadd -g $KAYOBE_USER_GID -o stack &&  \
    useradd -u $KAYOBE_USER_UID -g $KAYOBE_USER_GID \
    -G wheel -m -d /stack \
    -o -s /bin/bash stack
RUN echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN mkdir -p /secrets && \
    chown stack /secrets

COPY docker-entrypoint.sh /bin/entrypoint.sh
RUN chmod +x /bin/entrypoint.sh

WORKDIR /stack
USER stack

ENV SRC_PATH=/stack/src
ENV VENVS_PATH=/stack/venvs
ENV VIRTUAL_ENV="$VENVS_PATH/kayobe"

RUN python -m virtualenv --python=/usr/bin/python $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ARG kayobe_version='7.0.0'
ARG kayobe_repo='https://git.openstack.org/openstack/kayobe.git'

RUN git clone $kayobe_repo -b $kayobe_version $SRC_PATH/kayobe

RUN pip install -U pip && \
    pip install -U $SRC_PATH/kayobe

ENV KAYOBE_CONFIG_ROOT=$SRC_PATH/kayobe_config
COPY --chown=stack:stack . $KAYOBE_CONFIG_ROOT
COPY --chown=stack:stack ansible.cfg /stack/.ansible.cfg

ENV KAYOBE_CONFIG_PATH=$KAYOBE_CONFIG_ROOT/etc/kayobe
ENV KOLLA_CONFIG_PATH=$KAYOBE_CONFIG_ROOT/etc/kolla

ENV KOLLA_SOURCE_PATH=$SRC_PATH/kolla-ansible
ENV KOLLA_VENV_PATH=$VENVS_PATH/kolla-ansible

RUN kayobe control host bootstrap && rm -rf $HOME/.ssh

ENTRYPOINT ["/bin/entrypoint.sh"]
