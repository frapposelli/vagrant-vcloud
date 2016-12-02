#!/bin/bash

image=plossys/vagrant-vcloud

docker run --rm -it \
  -v "$(pwd):/work" \
  -v ~/.vagrant.d/Vagrantfile:/user/Vagrantfile \
  -e VCLOUD_USERNAME -e VCLOUD_PASSWORD \
  "$image" "$@"
