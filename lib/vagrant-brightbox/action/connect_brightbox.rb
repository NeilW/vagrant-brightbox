require "fog/brightbox"
require "log4r"

module VagrantPlugins
  module Brightbox
    module Action
      # This action connects to Brightbox, verifies credentials work, and
      # puts the Brightbox connection object into the `:brightbox_compute` key
      # in the environment.
      class ConnectBrightbox
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::connect_brightbox")
        end

        def call(env)
          # Get the region we're going to booting up in
          region = env[:machine].provider_config.region

          # Get the configs
          region_config     = env[:machine].provider_config.get_region_config(region)
          client_id     = region_config.client_id
	  client_secret = region_config.secret
	  username      = region_config.username
	  password      = region_config.password
	  account       = region_config.account
	  auth_url      = region_config.auth_url
	  api_url       = region_config.api_url

          @logger.info("Connecting to Brightbox...")
	  @logger.info("Fog credentials are: #{Fog.credentials.inspect}")
	  fog_options={
            :provider => :brightbox,
	    :brightbox_auth_url => auth_url,
	    :brightbox_api_url => api_url,
	    :brightbox_client_id => client_id,
	    :brightbox_secret => client_secret,
	    :brightbox_username => username,
	    :brightbox_password => password,
	    :brightbox_account => account,
          }
	  fog_options.delete_if {|k, v| v.nil? }
	  @logger.info("Fog compute options are: #{fog_options.inspect}")
          env[:brightbox_compute] = Fog::Compute.new(fog_options)

          @app.call(env)
	rescue ArgumentError => e
	  raise Errors::FogError, :message => e.message
        end
      end
    end
  end
end
