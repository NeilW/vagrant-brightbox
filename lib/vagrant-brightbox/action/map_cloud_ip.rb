require 'log4r'

module VagrantPlugins
  module Brightbox
    module Action
      class MapCloudIp

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::map_cloud_ips")
        end

        def call(env)

          @app.call(env)

	  machine = env[:machine]

	  if no_cloud_ips_required?(env[:machine].config.vm.networks)
	    @logger.info("No public ipv4 network required")
	    return
	  end

	  if machine.id.nil?
	    @logger.info("No server found - can't map public ips")
	    return
	  end

	  server = env[:brightbox_compute].servers.get(machine.id)
	  if server.nil?
	    @logger.info("Machine cannot be found; assuming it got destroyed.")
	    machine.id = nil
	    return
	  end

	  unless server.cloud_ips.empty?
	    @logger.info("Server already has public ip address.")
	    return
	  end

	  target_ip = unallocated_cloud_ip(env[:brightbox_compute].cloud_ips)

	  if target_ip.nil?
	    @logger.info("Couldn't allocate a cloud ip")
	    env[:ui].info I18n.t("vagrant_brightbox.errors.no_free_cloud_ip")
	    return
	  end

	  target_ip.map(server)
	  env[:ui].info I18n.t("vagrant_brightbox.mapped_cloud_ip", :server => server.id, :cloud_ip => target_ip.public_ip)

        end

	def unallocated_cloud_ip(ip_list)
	  ip_list.all.detect(ip_list.method(:allocate)) {|ip| !ip.mapped? }
	end

	def no_cloud_ips_required?(networks)
	  networks.any? do |x|
	    x.first == :private_network ||
	      (x.first == :public_network && element[1][:ipv6])
	  end
	end

      end
    end
  end
end
