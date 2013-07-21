# vagrant-vcloud #

Vagrant provider for VMware vCloud Director

Please note that this is NOT WORKING yet.

## TODO ##

Using this page as a reminder todo list to what needs to be done to integrate
vCloud Director with vagrant, at a high level.

### Vagrant Actions ###

*   Box

    TBD

*   Destroy
    
    This is a pretty simple action to implement in vCloud Director, as the vApp 
    is the top level object that contains the whole configuration of the setup.

    Deleting the vApp will clean all the objects contained within that vApp
    such as:
    *   vApp Metadata
    *   vApp Networks (including the NAT & Portforarding rules)
    *   All the VMs and their configuration

    This could look like:

    `env[:vcloud_connection].delete_vapp(vAppId)`


*   Halt

    This is a pretty simple action to implement in vCloud Director, as the vApp
    is the top layer object that contains the whole configuration of the setup.

    This could look like:

    `env[:vcloud_connection].poweroff_vapp(vAppId)`

*   Init
    
    TBD

*   Package

    Nothing to do here at the moment:

    [This command cannot be used with any other provider] (http://docs.vagrantup.com/v2/cli/package.html)

*   Plugin

    N/A

*   Provision

    TBD

*   Reload

    TBD

*   Resume

    This is a pretty simple action to implement in vCloud Director, as the vApp
    is the top layer object that contains the whole configuration of the setup.

    This could look like:

    `env[:vcloud_connection].poweron_vapp(vAppId)`

*   Ssh

    As the vApp is using a vShield Edge device to NAT using portforwarding mode,
    we will need to fetch the portforwarding rules used for SSH, and then map 
    them correctly to the configuration.

    Those two methods could be called to check for information and map the 
    information accordingly:

    `env[:vcloud_connection].get_vapp_edge_public_ip(vAppId)`
    `env[:vcloud_connection].get_vapp_port_forwarding_rules(vAppId)`


*   Ssh-Config

    This will likely need the information used on the previous section "Ssh"

*   Status

    This will display the state of the vApp and it's overall configuration.
    vApp status, VM status, and Network NAT rules for example would be nice.

    `env[:vcloud_connection].get_vapp(vAppId)`
    `env[:vcloud_connection].get_vapp_port_forwarding_rules(vAppId)`

*   Suspend

    This is a pretty simple action to implement in vCloud Director, as the vApp
    is the top layer object that contains the whole configuration of the setup.

    This could look like:

    `env[:vcloud_connection].suspend_vapp(vAppId)`

*   Up

    This is probably the most important action.
    It will basically compose the vApp from all the properties in the Vagrant 
    file, deploy that vApp, and power it on.

    Code that would be used:

    `env[:vcloud_connection].compose_vapp_from_vm(vdc, vapp_name, vapp_description, vm_list={}, network_config={})`
    `env[:vcloud_connection].set_vapp_port_forwarding_rules(vappid, network_name, config={})`     
    `env[:vcloud_connection].start_vapp(vAppId)`
