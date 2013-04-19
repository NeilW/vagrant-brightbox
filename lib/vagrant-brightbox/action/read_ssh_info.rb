require "log4r"

module VagrantPlugins
  module Brightbox
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfo
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::read_ssh_info")
        end

        def call(env)
          env[:machine_ssh_info] = read_ssh_info(env[:brightbox_compute], env[:machine])

          @app.call(env)
        end

        def read_ssh_info(brightbox, machine)
          return nil if machine.id.nil?

          # Find the machine
          server = brightbox.servers.get(machine.id)
          if server.nil?
            # The machine can't be found
            @logger.info("Machine couldn't be found, assuming it got destroyed.")
            machine.id = nil
            return nil
          end

	  if use_private_network?(machine.config.vm.networks)
	    host_name = server.fqdn
	  elsif use_ipv6_public_network?(machine.config.vm.networks)
	    host_name = "ipv6.#{server.fqdn}"
	  elsif server.public_ip_address
	    host_name = server.dns_name
	  else
	    @logger.error("Cannot find public ip address - defaulting to private")
	    host_name = server.fqdn
	  end

          # Read the DNS info
          return {
            :host => host_name,
            :port => 22
          }
        end

	def use_private_network?(network_structure)
	  network_structure.any? {|x| x.first == :private_network }
	end

	def use_ipv6_public_network?(network_structure)
	  network_structure.any? do |element|
	    element.first == :public_network && element[1][:ipv6]
	  end
	end

      end
    end
  end
end
