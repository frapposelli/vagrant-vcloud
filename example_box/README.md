# vagrant-vcloud box specifications [WIP]

*Note that vagrant-vcloud currently supports only single VM vApp boxes*

BOX package should contain:

- `metadata.json` -- Vagrant metadata file
- `<boxname>.ovf` -- OVF descriptor of the vApp.
- `<boxname>.mf` -- OVF manifest file containing file hashes.
- `<boxname>-disk-<#>.vmdk` -- Associated VMDK files.
- `Vagrantfile`-- vagrant-vcloud default Vagrantfile
