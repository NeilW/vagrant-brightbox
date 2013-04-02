require "log4r"

module VagrantPlugins
  module Brightbox
    module Action
      # This starts the server via the api
      class StartServer
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::start_server")
        end

        def call(env)
          server = env[:brightbox_compute].servers.get(env[:machine].id)

	  # Make the action idempotent
	  unless server.ready?
	    # start the server.
	    env[:ui].info(I18n.t("vagrant_brightbox.starting_server"))
	    server.start
	  end

          @app.call(env)
        end
      end
    end
  end
end
