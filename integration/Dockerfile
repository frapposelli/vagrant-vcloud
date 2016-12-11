FROM ubuntu

ARG VAGRANT_VERSION=1.9.1

ENV	\
  BOX_WINDOWS=https://github.com/plossys/vagrant-vcloud/raw/my/helper/dummy-windows.box \
  BOX_LINUX=https://github.com/plossys/vagrant-vcloud/raw/my/helper/dummy-linux.box

RUN apt-get update -y && \
    apt-get install -y build-essential liblzma-dev zlib1g-dev git openssh-client rsync curl && \
    ln -sf bash /bin/sh && \
    curl -L https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}_x86_64.deb > /tmp/vagrant_x86_64.deb && \
    dpkg -i /tmp/vagrant_x86_64.deb && \
    rm -f /tmp/vagrant_x86_64.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    vagrant plugin list && \
    ln -s /user/Vagrantfile /root/.vagrant.d/Vagrantfile && \
    vagrant box add windows_2016 ${BOX_WINDOWS} && \
    vagrant box add ubuntu1404 ${BOX_LINUX}

WORKDIR /plugin
COPY . /plugin

RUN /opt/vagrant/embedded/bin/gem build vagrant-vcloud.gemspec && \
    vagrant --version && \
    vagrant plugin install ./vagrant-vcloud*.gem && \
    vagrant plugin list

WORKDIR /work

VOLUME ["/work", "/user"]

ENTRYPOINT ["vagrant"]
