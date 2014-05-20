[Vagrant](http://www.vagrantup.com) provider for VMware vCloud Director®
=============

[Version 0.3.2](../../releases/tag/v0.3.2) has been released!
-------------

Please note that this software is still Alpha/Beta quality and is not recommended for production usage.

Right now a [Precise32](http://vagrant.tsugliani.fr/precise32.box) is available for use, or you can roll your own as you please, make sure to install VMware tools in it.

If you're unsure about what are the correct network settings for your Vagrantfile make sure to check out the [Network Deployment Options](https://github.com/frapposelli/vagrant-vcloud/wiki/Network-Deployment-Options) wiki page.

Features of Version 0.3.2 are:

- Added support for ```vagrant share``` command [[#31](https://github.com/frapposelli/vagrant-vcloud/issues/31)] Support vagrant share
- Restructured the ```vagrant vcloud-status``` to ```vagrant vcloud status``` for future-proofing [[#53](https://github.com/frapposelli/vagrant-vcloud/issues/53)]
- Added ```vagrant vcloud --redeploy-edge-gw``` to redeploy Edge Gateway [[#54](https://github.com/frapposelli/vagrant-vcloud/issues/54)]
- Several Bug Fixes [[#45](https://github.com/frapposelli/vagrant-vcloud/issues/45)], [[#46](https://github.com/frapposelli/vagrant-vcloud/issues/46)], [[#47](https://github.com/frapposelli/vagrant-vcloud/issues/47)], [[#48](https://github.com/frapposelli/vagrant-vcloud/issues/48)], [[#50](https://github.com/frapposelli/vagrant-vcloud/issues/50)], [[#51](https://github.com/frapposelli/vagrant-vcloud/issues/51)], [[#52](https://github.com/frapposelli/vagrant-vcloud/issues/52)], [[#56](https://github.com/frapposelli/vagrant-vcloud/issues/56)], [[#57](https://github.com/frapposelli/vagrant-vcloud/issues/57)], [[#61](https://github.com/frapposelli/vagrant-vcloud/issues/61)]

Features of Version 0.3.1 are:

- Small hotfix to include "preRunning" condition when using vCloud Director 5.5 [[#44](https://github.com/frapposelli/vagrant-vcloud/issues/44)]. - [Andrew Poland](https://github.com/apoland)

Features of Version 0.3.0 are:

A substantial release, major kudos to [Stefan Scherer](https://github.com/StefanScherer) who submitted some substantious PRs!

- Added support for port mapping at the Organization Edge Gateway.
- Added a new configuration options ```vapp_prefix``` to change vApp prefix (defaults to Vagrant).
- Improved vcloud-status command.
- Fixed cygdrive path for rsync on Windows.
- Fixed Issue [[#33](../../issues/33)] - Error removing/creating NAT rules on second vagrant up.
- Fixed Issue [[#43](../../issues/43)] - Destroy fails if VMs are halted.

Features of Version 0.2.2 are:

- Fixed Issue [[#32](../../issues/32)] - Port Forwarding rules are deleted when Halting a VM.

Features of Version 0.2.1 are:

- Critical Bugfixes

Features of Version 0.2.0 are:

- It's now possible to connect to an existing VDC network without creating a vShield Edge using ```network_bridge = true``` in the Vagrantfile [[#23](../../issues/23)]. *experimental*
- Added a ```upload_chunksize``` parameter to specify the chunk dimension during box uploads [[#21](../../issues/21)].
- Added support for [vCloud® Hybrid Service™](http://www.vmware.com/products/vcloud-hybrid-service) API version 5.7.
- Added a new command to vagrant called ```vcloud-status``` that shows the current status of the vCloud instance relative to the Vagrant deployment. *experimental*
- General code cleanup, code should be more readable and there's a rubocop file for our code conventions.
- Passwords are now hidden when running in DEBUG mode.
- Initial support for Vagrant 1.5 (currently not supporting the new "share" features).
- Lowered Nokogiri requirement to 1.5.5 (you may need to remove a later version if installed).
- Fixed the Edge Gateway NAT rules creation / deletion.
- Added debug capabilities down to XML traffic exchanged during the REST calls.


Check the full releases changelog [here](../../releases)

Install
-------------

Latest version can be easily installed by running the following command:

```vagrant plugin install vagrant-vcloud```

Vagrant will download all the required gems during the installation process.

After the install has completed a ```vagrant up --provider=vcloud``` will trigger the newly installed provider.

Configuration
-------------

Here's a sample Multi-VM Vagrantfile, please note that ```vcloud.vdc_edge_gateway``` and ```vcloud.vdc_edge_gateway_ip``` are required only when you cannot access ```vcloud.vdc_network_name``` directly and there's an Organization Edge between your workstation and the vCloud Network.

```ruby
precise32_vm_box_url = "http://vagrant.tsugliani.fr/precise32.box"

nodes = [
  { :hostname => "web-vm",  :box => "precise32", :box_url => precise32_vm_box_url },
  { :hostname => "ssh-vm",  :box => "precise32", :box_url => precise32_vm_box_url },
  { :hostname => "sql-vm",  :box => "precise32", :box_url => precise32_vm_box_url },
  { :hostname => "lb-vm",   :box => "precise64", :box_url => precise32_vm_box_url },
  { :hostname => "app-vm",  :box => "precise32", :box_url => precise32_vm_box_url },
]

Vagrant.configure("2") do |config|

  # vCloud Director provider settings
  config.vm.provider :vcloud do |vcloud|
    vcloud.vapp_prefix = "multibox-sample"

    vcloud.hostname = "https://my.cloudprovider.com"
    vcloud.username = "MyUserName"
    vcloud.password = "MySup3rS3cr3tPassw0rd!"
 
    vcloud.org_name = "OrganizationName"
    vcloud.vdc_name = "vDC_Name"

    vcloud.catalog_name = "Vagrant"
    vcloud.ip_subnet = "172.16.32.125/255.255.255.240"
    
    vcloud.vdc_network_name = "MyNetwork"

    vcloud.vdc_edge_gateway = "MyOrgEdgeGateway"
    vcloud.vdc_edge_gateway_ip = "10.10.10.10"
  end

  nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = node[:box]
      node_config.vm.hostname = node[:hostname]
      node_config.vm.box_url = node[:box_url]
      node_config.vm.network :forwarded_port, guest: 80, host: 8080, auto_correct: true
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
