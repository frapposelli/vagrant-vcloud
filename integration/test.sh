#!/bin/bash

if [[ $1 == '--help' || $1 == '' ]]; then
  echo "A helper to test plugin sources with several Vagrant versions."
  echo "Usage: $0 <image> <command>"
  echo "Examples:"
  echo "$0 vagrant:1.7.4 up"
  echo "$0 vagrant:1.8.7 up"
  echo "$0 vagrant:1.9.1 up"
  echo "$0 vagrant:1.9.1 destroy -f"
  exit 0
fi

image=$1
shift

docker run --rm -it \
  -v "$(pwd):/work" \
  -v ~/.vagrant.d/Vagrantfile:/user/Vagrantfile \
  "$image" "$@"
