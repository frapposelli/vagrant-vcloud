require 'pathname'
require 'vagrant/action/builder'

module VagrantPlugins
  module VCloud
    # This module dictates the actions to be performed by Vagrant when called
    # with a specific command
    module Action
      include Vagrant::Action::Builtin

      # Vagrant commands
      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use PowerOn
          b.use Call, IsCreated do |env, b2|
            unless env[:bridged_network]
              b2.use HandleNATPortCollisions
              b2.use ForwardPorts
            end
          end
          b.use WaitForCommunicator, [:starting, :running]
          b.use Provision
          b.use SyncFolders
        end
      end

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use action_halt
            b2.use action_start
            b2.use DisconnectVCloud
          end
        end
      end

      # This action starts a VM, assuming it is already imported and exists.
      # A precondition of this action is that the VM exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVCloud
          b.use Call, IsRunning do |env, b2|
            # If the VM is running, then our work here is done, exit
            if env[:result]
              b2.use MessageAlreadyRunning
            else
              b2.use PowerOn
            end
          end
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVCloud
          b.use Call, IsPaused do |env, b2|
            b2.use Resume if env[:result]
          end
          b.use PowerOff
        end
      end

      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectVCloud
          b.use Call, IsRunning do |env, b2|
            # If the VM is stopped, can't suspend
            if !env[:result]
              b2.use MessageCannotSuspend
            else
              b2.use Suspend
            end
          end
        end
      end

      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectVCloud
          b.use Resume
        end
      end

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, DestroyConfirm do |env, b2|
            if env[:result]
              b2.use ConfigValidate
              b2.use ConnectVCloud
              b2.use Call, IsCreated do |env2, b3|
                unless env2[:result]
                  b3.use MessageNotCreated
                  next
                end

                b3.use Call, IsRunning do |env3, b4|
                # If the VM is running, must power off
                  b4.use action_halt if env3[:result]
                end
                b3.use Call, IsLastVM do |env3, b4|
                  if env3[:result]
                    # Check if the network is bridged
                    b4.use Call, IsBridged do |env4, b5|
                      # if it's not, delete port forwardings.
                      b5.use UnmapPortForwardings unless env4[:bridged_network]
                    end
                    b4.use PowerOffVApp
                    b4.use DestroyVApp
                  else
                    b4.use DestroyVM
                  end
                end
              end
            else
              b2.use MessageWillNotDestroy
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use Provision
            b2.use SyncFolders
          end
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectVCloud
          b.use ReadSSHInfo, 22
        end
      end

      def self.action_read_winrm_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectVCloud
          b.use ReadSSHInfo, 5985
        end
      end

      def self.action_read_rdp_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConnectVCloud
          b.use ReadSSHInfo, 3389
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectVCloud
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          # b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, IsRunning do |env2, b3|
              unless env2[:result]
                b3.use MessageNotRunning
                next
              end
              # This calls our helper that announces the IP used to connect
              # to the VM, either directly to the vApp vShield or to the Org Edge
              b3.use AnnounceSSHExec
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            unless env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SSHRun
          end
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            b2.use HandleBox unless env[:result]
          end
          b.use ConnectVCloud
          b.use InventoryCheck
          b.use Call, IsCreated do |env, b2|
            if env[:result]
              b2.use action_start
            else
              b2.use BuildVApp
              b2.use action_boot
            end
          end
          b.use DisconnectVCloud
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path('../action', __FILE__))
      autoload :AnnounceSSHExec,
               action_root.join('announce_ssh_exec')
      autoload :BuildVApp,
               action_root.join('build_vapp')
      autoload :ConnectVCloud,
               action_root.join('connect_vcloud')
      autoload :DestroyVM,
               action_root.join('destroy_vm')
      autoload :DestroyVApp,
               action_root.join('destroy_vapp')
      autoload :DisconnectVCloud,
               action_root.join('disconnect_vcloud')
      autoload :ForwardPorts,
               action_root.join('forward_ports')
      autoload :HandleNATPortCollisions,
               action_root.join('handle_nat_port_collisions')
      autoload :InventoryCheck,
               action_root.join('inventory_check')
      autoload :IsCreated,
               action_root.join('is_created')
      autoload :IsBridged,
               action_root.join('is_bridged')
      autoload :IsPaused,
               action_root.join('is_paused')
      autoload :IsRunning,
               action_root.join('is_running')
      autoload :IsLastVM,
               action_root.join('is_last_vm')
      autoload :MessageAlreadyRunning,
               action_root.join('message_already_running')
      autoload :MessageNotRunning,
               action_root.join('message_not_running')
      autoload :MessageCannotSuspend,
               action_root.join('message_cannot_suspend')
      autoload :MessageNotCreated,
               action_root.join('message_not_created')
      autoload :MessageWillNotDestroy,
               action_root.join('message_will_not_destroy')
      autoload :PowerOff,
               action_root.join('power_off')
      autoload :PowerOffVApp,
               action_root.join('power_off_vapp')
      autoload :PowerOn,
               action_root.join('power_on')
      autoload :ReadSSHInfo,
               action_root.join('read_ssh_info')
      autoload :ReadState,
               action_root.join('read_state')
      autoload :Resume,
               action_root.join('resume')
      autoload :Suspend,
               action_root.join('suspend')
      autoload :SyncFolders,
               action_root.join('sync_folders')
      autoload :UnmapPortForwardings,
               action_root.join('unmap_port_forwardings')
    end
  end
end
