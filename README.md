[Vagrant](http://www.vagrantup.com) provider for VMware vCloud Director® [![Gem Version](https://badge.fury.io/rb/vagrant-vcloud.svg)](http://badge.fury.io/rb/vagrant-vcloud) [![Code Climate](https://codeclimate.com/github/frapposelli/vagrant-vcloud/badges/gpa.svg)](https://codeclimate.com/github/frapposelli/vagrant-vcloud)
=============

[![Join the chat at https://gitter.im/frapposelli/vagrant-vcloud](https://badges.gitter.im/frapposelli/vagrant-vcloud.svg)](https://gitter.im/frapposelli/vagrant-vcloud?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Please note that this software is still Alpha/Beta quality and is not recommended for production usage.

We have a wide array of boxes available at [Vagrant Cloud](https://vagrantcloud.com/gosddc) you can use them directly or you can roll your own as you please, make sure to install VMware tools in it.

Starting from [version 0.4.2](../../releases/tag/v0.4.2), this plugin supports the universal [```vmware_ovf``` box format](https://github.com/gosddc/packer-post-processor-vagrant-vmware-ovf/wiki/vmware_ovf-Box-Format), that is 100% portable between [vagrant-vcloud](https://github.com/frapposelli/vagrant-vcloud), [vagrant-vcenter](https://github.com/gosddc/vagrant-vcenter) and [vagrant-vcloudair](https://github.com/gosddc/vagrant-vcloudair), no more double boxes!.

If you're unsure about what are the correct network settings for your Vagrantfile make sure to check out the [Network Deployment Options](https://github.com/frapposelli/vagrant-vcloud/wiki/Network-Deployment-Options) wiki page.

Check the full releases changelog [here](../../releases)

Install
-------------

Latest version can be easily installed by running the following command:

```vagrant plugin install vagrant-vcloud```

Vagrant will download all the required gems during the installation process.

After the install has completed a ```vagrant up --provider=vcloud``` will trigger the newly installed provider.

Upgrade
-------------

If you already have vagrant-vcloud installed you can update to the latest version available by issuing:

```vagrant plugin update vagrant-vcloud```

Vagrant will take care of the upgrade process.

Configuration
-------------

Here's a sample Multi-VM Vagrantfile, please note that ```vcloud.vdc_edge_gateway``` and ```vcloud.vdc_edge_gateway_ip``` are required only when you cannot access ```vcloud.vdc_network_name``` directly and there's an Organization Edge between your workstation and the vCloud Network.

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

For additional documentation on different network setups with vCloud Director, check the [Network Deployment Options](../../wiki/Network-Deployment-Options) Wiki page

Contribute
-------------

What is still missing:

- TEST SUITES! (working on that).
- Speed, the code is definitely not optimized.
- Permission checks, make sure you have at least Catalog Admin privileges if you want to upload boxes to vCloud.
- Thorough testing.
- Error checking is absymal.
- Some spaghetti code here and there.
- Bugs, bugs and BUGS!.

If you're a developer and want to lend us a hand, head over to our ```develop``` branch and send us PRs!


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/frapposelli/vagrant-vcloud/trend.png)](https://bitdeli.com/free "Bitdeli Badge")
