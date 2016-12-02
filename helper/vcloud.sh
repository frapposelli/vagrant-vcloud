#!/bin/bash

image=plossys/vagrant-vcloud

if [ "$0" == "configure" ]; then
  docker run --rm -it --entrypoint retrieve-vagrant-vcloud-settings.sh "$image" "$@"
  exit 0
fi

docker run --rm -it \
  -v "$(pwd):/work" \
  -v ~/.vagrant.d/Vagrantfile:/user/Vagrantfile \
  -e VCLOUD_USERNAME -e VCLOUD_PASSWORD \
  "$image" "$@"
