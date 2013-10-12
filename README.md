[Vagrant](http://www.vagrantup.com) provider for VMware vCloud Director®
=============

[Version 0.1.0](https://github.com/frapposelli/vagrant-vcloud/releases/tag/v0.1.0) has been released!
-------------

Please note that this software is still Alpha/Beta quality and is not recommended for production usage.

Right now a [Precise32](http://vagrant.tsugliani.fr/precise32.box) is available for use, or you can roll your own as you please, make sure to install VMware tools in it.

Features of Version 0.1.0 are:

- Basic Create/Provision/Destroy lifecycle.
- Rsync-based provisioning (working on alternatives for that).
- Use a single vApp as a container for Multi-VM Vagrantfiles.
- Use a vApp vShield Edge to perform DNAT/SNAT on a single IP for Multi-VM Vagrantfiles.
- Automatically create NAT rules on a fronting Organization Edge.
- Automatic upload of the Vagrant box to the specified catalog.
- Works on [vCloud® Hybrid Service™](http://www.vmware.com/products/vcloud-hybrid-service)!

What is still missing:

- TEST SUITES! (working on that).
- Speed, the code is definitely not optimized.
- Permission checks, make sure you have at least Catalog Admin privileges if you want to upload boxes to vCloud.
- Thorough testing.
- Error checking is absymal.
- Some spaghetti code here and there.
- Bugs, bugs and BUGS!.

If you're a developer and want to lend us a hand, head over to our ```develop``` branch and get busy!

Install
-------------

Version 0.1.0 can be easily installed by running:

```vagrant plugin install vagrant-vcloud```

Vagrant will download all the required gems during the installation process.

After the install has completed a ```vagrant up --provider=vcloud``` will trigger the newly installed provider.

Here's a sample Multi-VM Vagrantfile, please note that ```vcloud.vdc_edge_gateway``` and ```vcloud.vdc_edge_gateway_ip``` are required only when you cannot access ```vcloud.vdc_network_name``` directly and there's an Organization Edge between your workstation and the vCloud Network.

```ruby
precise32_vm_box_url = "http://vagrant.tsugliani.fr/precise32.box"

nodes = [
  { :hostname => "web-vm",  :box => "precise32", :box_url => precise32_vm_box_url},
  { :hostname => "ssh-vm",  :box => "precise32" , :box_url => precise32_vm_box_url},
  { :hostname => "sql-vm",  :box => "precise32", :box_url => precise32_vm_box_url },
  { :hostname => "lb-vm",  :box => "precise64", :box_url => precise32_vm_box_url },
  { :hostname => "app-vm",  :box => "precise32", :box_url => precise32_vm_box_url },
]

Vagrant.configure("2") do |config|

  # vCloud Director provider settings
  config.vm.provider :vcloud do |vcloud|
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