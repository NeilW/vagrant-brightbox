require "log4r"

require 'vagrant/util/retryable'

require 'vagrant-brightbox/util/timer'

module VagrantPlugins
  module Brightbox
    module Action
      # This creates the Brightbox Server
      class CreateServer
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::create_server")
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          # Get the region we're going to booting up in
          region = env[:machine].provider_config.region

          # Get the configs
          region_config      = env[:machine].provider_config.get_region_config(region)
          image_id         = region_config.image_id
          zone             = region_config.zone
          server_name      = region_config.server_name
          server_type      = region_config.server_type
          server_groups    = region_config.server_groups

          # Launch!
          env[:ui].info(I18n.t("vagrant_brightbox.launching_server"))
          env[:ui].info(" -- Type: #{server_type}") if server_type
          env[:ui].info(" -- Image: #{image_id}") if image_id
          env[:ui].info(" -- Region: #{region}")
	  env[:ui].info(" -- Name: #{server_name}") if server_name
          env[:ui].info(" -- Zone: #{zone}") if zone
          env[:ui].info(" -- Server Groups: #{server_groups.inspect}") if !server_groups.empty?

          begin
            options = {
              :image_id           => image_id,
	      :name		  => server_name,
              :flavor_id          => server_type,
              :zone_id 		  => zone
            }

            if !server_groups.empty?
              options[:server_groups] = server_groups
            end

            server = env[:brightbox_compute].servers.create(options)
          rescue Excon::Errors::HTTPStatusError => e
            raise Errors::FogError, :message => e.response
          end

          # Immediately save the ID since it is created at this point.
          env[:machine].id = server.id

          # Wait for the server to build
          env[:metrics]["server_build_time"] = Util::Timer.time do
            env[:ui].info(I18n.t("vagrant_brightbox.waiting_for_build"))
            retryable(:on => Fog::Errors::TimeoutError, :tries => 30) do
              # If we're interrupted don't worry about waiting
              next if env[:interrupted]

              # Wait for the server to be ready
              server.wait_for(2) { ready? }
            end
          end

          @logger.info("Time for server to build: #{env[:metrics]["server_build_time"]}")

          if !env[:interrupted]
	    @app.call(env)
            env[:metrics]["instance_ssh_time"] = Util::Timer.time do
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t("vagrant_brightbox.waiting_for_ssh"))
              while true
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if ready?(env[:machine])
                sleep 2
              end
            end

            @logger.info("Time for SSH ready: #{env[:metrics]["instance_ssh_time"]}")

            # Ready and booted!
            env[:ui].info(I18n.t("vagrant_brightbox.ready"))
          end

          # Terminate the instance if we were interrupted
          terminate(env) if env[:interrupted]

        end

	# Check if machine is ready, trapping only non-fatal errors
	def ready?(machine)
	  @logger.info("Checking if SSH is ready or is permanently broken...")
	  @logger.info("Connecting as '#{machine.ssh_info[:username]}'") if machine.ssh_info[:username]
	  # Yes this is cheating.
	  machine.communicate.send(:connect)
	  @logger.info("SSH is ready")
	  true
	# Fatal errors
	rescue Vagrant::Errors::SSHAuthenticationFailed
	  raise
	# Transient errors
	rescue Vagrant::Errors::VagrantError => e
	  @logger.info("SSH not up: #{e.inspect}")
	  return false
	end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
