@echo off
setlocal
set curr=%cd:\=/%
set curr=%curr:C:=/c%
set home=%USERPROFILE:\=/%
set home=%home:C:=/c%
set image=plossys/vagrant-vcloud
if "%1" == "configure" (
  shift
  docker run --rm -it --entrypoint retrieve-vagrant-vcloud-settings.sh %image% %*
) else (
  docker run --rm -it -v %curr%:/work -v %home%/.vagrant.d/Vagrantfile:/user/Vagrantfile -e VCLOUD_USERNAME -e VCLOUD_PASSWORD %image% %*
)
