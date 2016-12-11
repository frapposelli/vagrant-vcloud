# integration

Easily run some integration tests with several versions of Vagrant in a Docker container.

## Build vagrant base images

To build the vagrant base images just run

```
./build-images.sh
```

This also tests if the plugin is installable in the latest three minor versions of Vagrant.

Afterwards you have some Docker images with specific Vagrant versions:

```
$ docker images | grep vagrant
vagrant                     1.7.4               4bd54f063310        About an hour ago   598.9 MB
vagrant                     1.8.7               9d70aa570e14        About an hour ago   594.1 MB
vagrant                     1.9.1               446c0fad9f55        About an hour ago   609.8 MB
```

## Run a test

In this folder there is a `Vagrantfile` with two VM's in a vApp. Spinning up that vApp you will test if rsync works and if adding a VM to a vApp works.

You can use all commands of Vagrant with that wrapper script `test.sh`. As first argument you have to specify the Docker image name, eg. `vagrant:1.9.1`

```
./test.sh vagrant:1.7.4 up
```

If you change some code you have to rebuild the base images at the moment.
