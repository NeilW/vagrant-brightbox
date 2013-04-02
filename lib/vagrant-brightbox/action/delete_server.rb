require "log4r"

module VagrantPlugins
  module Brightbox
    module Action
      # This terminates the running server
      class DeleteServer
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_brightbox::action::delete_server")
        end

        def call(env)
          server = env[:brightbox_compute].servers.get(env[:machine].id)

          # Destroy the server and remove the tracking ID
          env[:ui].info(I18n.t("vagrant_brightbox.deleting_server"))
          server.destroy
          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
