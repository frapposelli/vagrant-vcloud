# vagrant-vcloud [![Stories in Ready](http://badge.waffle.io/frapposelli/vagrant-vcloud.png)](http://waffle.io/frapposelli/vagrant-vcloud)  

Vagrant provider for VMware vCloud Director®

Please note that this is NOT WORKING yet.

## TODO ##

Using this page as a reminder todo list to what needs to be done to integrate
vCloud Director with vagrant, at a high level.

### Overall things to consider/fix ###

*   Handle vCloud Director blocking tasks

    This might surface at some point depending if this plugin is used in private 
    cloud environment with an approval process. (sigh)

*   Try multiple Catalog Items upload at the same time

    This might surface when working in the same organization as another developer
    and check if our error handling is working fine.

*   Check vCloud Username credentials (permissions for catalog for example)
    
    If trying to use a public Catalog from another Organization that process
    *will* fail.

    [x] This should be fixed.  

*   Wait for catalog item to be ready before processing to next step.

    If you do a catalog upload, and deploy right after, the catalog item is
    going through a ovf import process through vSphere which takes some time.

    [x] This should be fixed.  

*   Set the VM guest customization default password to 'vagrant'

    The vApp will actually not power on successfully with guest customization
    enabled, and a blank password.

    [x] This should be fixed.  

*   Avoid serializing vApp/Virtual Machine build when multi Virtual Machines

    Find a way to avoid doing the following steps:  
    - Create vApp  
    - Create VM1  
    - Boot & Guest Customize VM1  
    - Applying network port forwarding rules  
    - Create VM2  
    - Boot & Guest Customize VM2  
    - Applying network port forwarding rules  
    - repeat for every VM...  

    This would avoid spending a lot of time for each VM on the boot/reboot process
    for the guest customization process.

    [x] This should be fixed.

*   Inconsistency to fix on the following variable through the whole code/lib
    
    This should never happen ! (vm/vApp is confusing !)  
    :vm_scoped_local_id => rule[:VAppScopedVmId]

    We might need to clean some data structures between the driver/api  

### Vagrant Actions ###

*   Box

    We should provide a vCloud Director-ready OVF inside the box file, 
    and give the ability to upload the box to a Catalog 
    (if the user has catalog author permission) or leverage a pre-existing box 
    already in a catalog.

    [x] Create a new precise32 box for vCloud Director   
    [x] Ability to use a vCloud Director Catalog Template/Catalog item  
    [x] Ability to upload a local box into a vCloud Catalog Template/Catalog item  

    Url to fetch the current box:  
    [Precise32 box for vagrant-vcloud] (http://vagrant.tsugliani.fr/precise32.box)

*   Destroy
    
    This is a pretty simple action to implement in vCloud Director, as the vApp 
    is the top level object that contains the whole configuration of the setup.

    Deleting the vApp will clean all the objects contained within that vApp
    such as:
    *   vApp Metadata
    *   vApp Networks (including the NAT & Portforarding rules)
    *   All the VMs and their configuration

    [x] Destroying Virtual Machines is now possible using their predefined name  
    [x] When the last Virtual Machine is destroyed, vApp will be deleted  
    [x] Cleaning network NAT rules (portforwarding etc...)  

*   Halt

    This is a pretty simple action to implement in vCloud Director, as the vApp
    is the top layer object that contains the whole configuration of the setup.

    [x] Halting Virtual Machines is now possible using their predefined name  

*   Init
    
    TBD

*   Package

    Nothing to do here at the moment:

    [This command cannot be used with any other provider] (http://docs.vagrantup.com/v2/cli/package.html)

*   Provision

    TBD

*   Reload

    TBD

*   Resume

    This is a pretty simple action to implement in vCloud Director, as the vApp
    is the top layer object that contains the whole configuration of the setup.

    [x] Resuming/Starting Virtual Machines is now possible using their predefined name   

*   Ssh

    As the vApp is using a vShield Edge device to NAT using portforwarding mode,
    we will need to fetch the portforwarding rules used for SSH, and then map 
    them correctly to the configuration.

    Those two methods could be called to check for information and map the 
    information accordingly:

    [ ] Using unison to handle this part  

    ```ruby
    cnx = cfg.vcloud_cnx.driver  
    cnx.get_vapp_edge_public_ip(vAppId)  
    cnx.get_vapp_port_forwarding_rules(vAppId)
    ```  

*   Ssh-Config

    This will likely need the information used on the previous section "Ssh"

*   Status

    This will display the state of the vApp and it's overall configuration.
    vApp status, VM status, and Network NAT rules for example would be nice.

    [x] Checking the Virtual Machines status is now possible  

    ```Shell
    Current machine states:

    web-vm                   running (vcloud)
    ssh-vm                   suspended (vcloud)
    sql-vm                   stopped (vcloud)

    This environment represents multiple VMs. The VMs are all listed
    above with their current state. For more information about a specific
    VM, run `vagrant status NAME`.
    ```

*   Suspend

    This is a pretty simple action to implement in vCloud Director, as the vApp
    is the top layer object that contains the whole configuration of the setup.

    [x] Suspending the Virtual Machines status is now possible

*   Up

    This is probably the most important action.
    It will basically compose the vApp from all the properties in the Vagrant 
    file, deploy that vApp, and power it on.

    [x] Creating vApp   
    [x] Adding Virtual Machines to the vApp from configuration  
    [x] Post configuration of the Virtual Machine (Guest Customization)  
    [x] Configuration of the Network Port forwarding rules  
