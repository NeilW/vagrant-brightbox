module VagrantPlugins
  module Brightbox
    module Action
      class Unsupported
        def initialize(app, env)
          @app = app
        end

        def call(env)
	  env[:ui].warn(I18n.t("vagrant_brightbox.unsupported"))

          @app.call(env)
        end
      end
    end
  end
end

