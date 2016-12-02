# [Vagrant](http://www.vagrantup.com) provider for VMware vCloud Director®
[![Build Status](https://travis-ci.org/plossys/vagrant-vcloud.svg?branch=my)](https://travis-ci.org/plossys/vagrant-vcloud) [![](https://badge.imagelayers.io/plossys/vagrant-vcloud:latest.svg)](https://imagelayers.io/?images=plossys/vagrant-vcloud:latest 'Get your own badge on imagelayers.io')

This is a fork of [vagrant-vcloud](https://github.com/frapposelli/vagrant-vcloud) to adjust it for our purposes.

Check the full releases changelog [here](../../releases)

## Install

Use our Docker image [plossys/vagrant-vcloud](https://hub.docker.com/r/plossys/vagrant-vcloud/) to have Vagrant and the vagrant-vcloud plugin installed inside a Docker container.

So you don't have version conflicts with your local Vagrant installation if you
prefer a newer Version of Vagrant.

There is a helper script `vcloud` that should be installed on your local machine
in addition to a Docker engine.

### Linux

Download the [helper/vcloud.sh](https://github.com/plossys/vagrant-vcloud/blob/my/helper/vcloud.sh) script and put it into a directory of your PATH.

```bash
curl -o vcloud https://raw.githubusercontent.com/plossys/vagrant-vcloud/my/helper/vcloud.bat
chmod +x vcloud
```

### Windows

Download the [helper/vcloud.bat](https://github.com/plossys/vagrant-vcloud/blob/my/helper/vcloud.bat) script and put it into
a directory of your PATH.

```powershell
Invoke-WebRequest -Outfile vcloud.bat -Uri https://raw.githubusercontent.com/plossys/vagrant-vcloud/my/helper/vcloud.bat -UseBasicParsing
```

## Configuration

You can use the `vcloud configure` command to retrieve your vCloud org settings that should be placed in your global Vagrantfile.

```bash
vcloud configure --hostname yourCloud --username yourAccount --orgname yourOrg
```

It should show you something like this:

```
http: password for yourAccount@yourAOrg@yourCloud:
Put this lines to your global ~/.vagrant.d/Vagrantfile

Vagrant.configure("2") do |config|
  if Vagrant.has_plugin?("vagrant-vcloud")
    vcloud.hostname            = "https://yourCloud"
    vcloud.username            = "vagrant"
    vcloud.password            = ENV['VCLOUD_PASSWORD'] || "vagrant"
    vcloud.org_name            = "XX"
    vcloud.vdc_name            = "XX-VDC"
    vcloud.catalog_name        = "COM-BUILD-CATALOG"
    vcloud.ip_subnet           = "172.16.32.1/255.255.255.0"]
    vcloud.ip_dns              = ["1.2.3.4", "8.8.8.8"]
    vcloud.vdc_network_name    = "SS-INTERNAL"
    vcloud.vdc_edge_gateway    = "SS-EDGE"
    vcloud.vdc_edge_gateway_ip = "2.3.4.5"
  end
end
```

## Examples

Here's a sample Multi-VM Vagrantfile, please note that `vcloud.vdc_edge_gateway` and `vcloud.vdc_edge_gateway_ip` are required when you cannot access `vcloud.vdc_network_name` directly and there's an Organization Edge between your workstation and the vCloud Network.

```ruby
vapp = {
  name: 'My vApp name',
  org_name: 'OrganizationName',
  orgvdc_name: 'vDC_Name',
  orgvdccatalog_name: 'Vagrant',
  metadata: [ [ 'key', 'value' ] ],
  advanced_networking: true,
  networks: {
    org: [ 'Org_VDC_Network' ],
    vapp: [
      {
        name: 'MyNetwork',
        ip_subnet: '10.10.10.10/255.255.255.0'
      }
    ]
  }
}

nodes = [
  {
    hostname: 'web-vm',
    box: 'gosddc/precise32',
    memory: 512,
    cpus: 1,
    nested_hypervisor: false,
    add_hdds: [ 1024 ],
    power_on: true,
    ssh_enable: true,
    sync_enable: true,
    metadata: [ [ 'key', 'value' ] ],
    nics: [
      type: :vmxnet3,
      connected: true,
      network: "vApp netowrk",
      primary: true,
      ip_mode: "static",
      ip: "10.10.10.1",
      mac: "00:50:56:00:00:01"
    ],
    enable_guest_customization: true,
    guest_customization_script: 'touch /sample.file'
  },
  { hostname: 'ssh-vm', box: 'gosddc/precise32' },
  { hostname: 'sql-vm', box: 'gosddc/precise32' },
  { hostname: 'app-vm', box: 'gosddc/precise32' }
]

Vagrant.configure('2') do |config|

  # vCloud Director provider settings
  config.vm.provider :vcloud do |vcloud|

    vcloud.hostname = 'https://my.cloudprovider.com'
    vcloud.username = 'MyUserName'
    vcloud.password = 'MySup3rS3cr3tPassw0rd!'

    vcloud.vapp_prefix = 'multibox-sample'

    vcloud.org_name = vapp[:org_name]
    vcloud.vdc_name = vapp[:orgvdc_name]
    vcloud.catalog_name = vapp[:orgvdccatalog_name]

    vcloud.vapp_name = vapp[:name]
    vcloud.metadata_vapp = vapp[:metadata]
    vcloud.auto_yes_for_upload = vapp[:auto_yes_for_upload]

    vcloud.advanced_network = vapp[:advanced_networking]
    if vapp[:advanced_networking]
      vcloud.networks = vapp[:networks]
    else
      vcloud.ip_subnet = '172.16.32.125/255.255.255.240'
      vcloud.vdc_network_name = 'MyNetwork'
      vcloud.vdc_edge_gateway = 'MyOrgEdgeGateway'
      vcloud.vdc_edge_gateway_ip = '10.10.10.10'
      end
  end

  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = node[:box]
      node_config.vm.hostname = node[:hostname]
      node_config.vm.box_url = node[:box_url]
      if vapp[:advanced_networking]
        node_config.vm.provider :vcloud do |pro|
          pro.memory = node[:memory]
          pro.cpus = node[:cpus]
          pro.add_hdds = node[:add_hdds]
          pro.nics = node[:nics]
          pro.ssh_enabled = node[:ssh_enabled]
          pro.sync_enabled = node[:sync_enabled]
          pro.power_on = node[:power_on]
          pro.metadata_vm = node[:metadata]
          pro.nested_hypervisor = node[:nested_hypervisor]
          pro.enable_guest_customization = node[:enable_guest_customization]
          pro.guest_customization_script = node[:guest_customization_script]
        end
        node_config.vm.network :public_network
      else
        node_config.vm.network :forwarded_port,
                               guest: 80,
                               host: 8080,
                               auto_correct: true
      end
      # node_config.vm.provision :puppet do |puppet|
      #   puppet.manifests_path = 'puppet/manifests'
      #   puppet.manifest_file = 'site.pp'
      #   puppet.module_path = 'puppet/modules'
      # end
    end
  end
end
```

## Networking

For additional documentation on network setups with vCloud Director, check the [Network Deployment Options](https://github.com/frapposelli/vagrant-vcloud/wiki/Network-Deployment-Options) Wiki page

## Issue working on Windows

If you see the following error spinning up a Linux VM in vCloud from a Windows host

```
    p50: Vagrant insecure key detected. Vagrant will automatically replace
    p50: this with a newly generated keypair for better security.
    p50:
    p50: Inserting generated public key within guest...
    p50: Removing insecure key from the guest if it's present...
    p50: Key inserted! Disconnecting and reconnecting using new SSH key...
The private key to connect to this box via SSH has invalid permissions
set on it. The permissions of the private key should be set to 0600, otherwise SS
ignore the key. Vagrant tried to do this automatically for you but failed. Please
permissions on the following file to 0600 and then try running this command again

/work/.vagrant/machines/p50/vcloud/private_key

Note that this error occurs after Vagrant automatically tries to
do this for you. The likely cause of this error is a lack of filesystem
permissions or even filesystem functionality. For example, if your
Vagrant data is on a USB stick, a common case is that chmod is
not supported. The key will need to be moved to a filesystem that
supports chmod.
```

then you have to skip the SSH key by adding the following line into your `Vagrantfile`:

```ruby
    cfg.ssh.insert_key = false # to work with vcloud.bat from a Windows hostname
```

## Contribute

What is still missing:

-	TEST SUITES! (working on that).
-	Speed, the code is definitely not optimized.
-	Permission checks, make sure you have at least Catalog Admin privileges if you want to upload boxes to vCloud.
-	Thorough testing.
-	Error checking is absymal.
-	Some spaghetti code here and there.
-	Bugs, bugs and BUGS!.

If you're a developer and want to lend us a hand, head over to our `my` branch and send us PRs!
