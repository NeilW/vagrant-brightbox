require "vagrant"

module VagrantPlugins
  module Brightbox
    module Errors
      class VagrantBrightboxError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_brightbox.errors")
      end

      class FogError < VagrantBrightboxError
        def initialize(message = nil, *args)
	  if message.is_a?(Hash)
	    target = message[:message]
	    if target.respond_to?(:body)
	      puts target.body.inspect
	      decode = Fog::JSON.decode(target.body)
	      if decode["errors"] 
		message[:message] = decode["error_name"]+":\n"+decode["errors"].join("\n")
	      elsif decode["error_description"]
	        message[:message] = decode["error"] + ": " + decode["error_description"]
	      end
	    end
	  end
	  super
	end
        error_key(:fog_error)
      end

      class RsyncError < VagrantBrightboxError
        error_key(:rsync_error)
      end
    end
  end
end
