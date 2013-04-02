require "vagrant"

module VagrantPlugins
  module Brightbox
    module Errors
      class VagrantBrightboxError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_brightbox.errors")
      end

      class FogError < VagrantBrightboxError
        error_key(:fog_error)
      end

      class RsyncError < VagrantBrightboxError
        error_key(:rsync_error)
      end
    end
  end
end
