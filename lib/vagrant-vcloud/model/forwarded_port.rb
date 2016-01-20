module VagrantPlugins
  module VCloud
    module Model
      # Represents a single forwarded port for VirtualBox. This has various
      # helpers and defaults for a forwarded port.
      class ForwardedPort
        # If true, this port should be auto-corrected.
        #
        # @return [Boolean]
        attr_reader :auto_correct

        # The unique ID for the forwarded port.
        #
        # @return [String]
        attr_reader :id

        # The protocol to forward.
        #
        # @return [String]
        attr_reader :protocol

        # The IP that the forwarded port will connect to on the guest machine.
        #
        # @return [String]
        attr_reader :guest_ip

        # The port on the guest to be exposed on the host.
        #
        # @return [Integer]
        attr_reader :guest_port

        # The IP that the forwarded port will bind to on the host machine.
        #
        # @return [String]
        attr_reader :host_ip

        # The port on the host used to access the port on the guest.
        #
        # @return [Integer]
        attr_reader :host_port

        # The network name to forward from.
        #
        # @return [String]
        attr_reader :network_name

        # The network name to forward to.
        #
        # @return [String]
        attr_reader :edge_network_name

        # The id of the parent network.
        #
        # @return [String]
        attr_reader :edge_network_id

        # The id of the vm nic.
        #
        # @return [Integer]
        attr_reader :vmnic_id

        def initialize(id, host_port, guest_port, network_name, edge_network_id, edge_network_name, options)
          @id                = id
          @guest_port        = guest_port
          @host_port         = host_port
          @network_name      = network_name
          @edge_network_id    = edge_network_id
          @edge_network_name = edge_network_name

          options ||= {}
          @auto_correct = false
          if options.key?(:auto_correct)
            @auto_correct = options[:auto_correct]
          end
          @guest_ip = options[:guest_ip] || nil
          @host_ip = options[:host_ip] || nil
          @protocol = options[:protocol] || 'tcp'
          @vmnic_id = options[:vmnic_id] || 0
        end

        # This corrects the host port and changes it to the given new port.
        #
        # @param [Integer] new_port The new port
        def correct_host_port(new_port)
          @host_port = new_port
        end
      end
    end
  end
end
