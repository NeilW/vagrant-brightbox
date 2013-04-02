require "log4r"

module VagrantPlugins
  module Brightbox
    module Action
      # This halts the running server via the api
      class ForcedHalt
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::forced_halt")
        end

        def call(env)
          server = env[:brightbox_compute].servers.get(env[:machine].id)

	  if server.ready?
	    # Stop the server.
	    env[:ui].info(I18n.t("vagrant_brightbox.stopping_server"))
	    server.stop
	  end

          @app.call(env)
        end
      end
    end
  end
end
