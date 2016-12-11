#!/bin/bash
MY_PATH="`dirname \"$0\"`"              # relative
MY_PATH="`( cd \"$MY_PATH\" && pwd  )`"  # absolutized and normalized
cd $MY_PATH/..
docker build -t vagrant:1.9.1 --build-arg VAGRANT_VERSION=1.9.1 -f integration/Dockerfile .
docker build -t vagrant:1.8.7 --build-arg VAGRANT_VERSION=1.8.7 -f integration/Dockerfile .
docker build -t vagrant:1.7.4 --build-arg VAGRANT_VERSION=1.7.4 -f integration/Dockerfile .
