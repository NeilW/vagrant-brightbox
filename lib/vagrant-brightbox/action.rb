require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module Brightbox
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to destroy the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
	  b.use Call, DestroyConfirm do |env, b2|
	    if env[:result]
	      b2.use ConfigValidate
	      b2.use Call, IsCreated do |env2, b3|
		if env2[:result]
		  b3.use ConnectBrightbox
		  b3.use DeleteServer
		else
		  b3.use MessageNotCreated
		end
	      end
	    else
	      b2.use MessageWillNotDestroy
	    end
	  end
        end
      end

      # This action is called to halt the server - gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
	  b.use ConfigValidate
	  b.use Call, IsCreated do |env, b2|
	    if env[:result]
	      b2.use Call, GracefulHalt, :inactive, :active do |env2, b3|
	        if !env2[:result]
		  b3.use ConnectBrightbox
		  b3.use ForcedHalt
		end
	      end
	    else
	      b2.use MessageNotCreated
	    end
	  end
	end
      end

      # This action reloads the machine - essentially shutting it down
      # and bringing it back up again in the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
	  b.use Call, IsCreated do |env, b2|
	    if env[:result]
	      b2.use action_halt
	      b2.use action_up
	    else
	      b2.use MessageNotCreated
	    end
	  end
	end
      end

      # This action is called when `vagrant provision` is called.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if env[:result]
	      b2.use Provision
	      b2.use SyncFolders
	    else
              b2.use MessageNotCreated
            end
          end
        end
      end
      

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectBrightbox
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectBrightbox
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if env[:result]
	      b2.use SSHExec
	    else
              b2.use MessageNotCreated
            end
          end
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
	  b.use ConfigValidate
	  b.use Call, IsCreated do |env, b2|
	    if env[:result]
	      b2.use SSHRun
	    else
	      b2.use MessageNotCreated
	    end
	  end
	end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
	  b.use HandleBoxUrl
          b.use ConfigValidate
	  b.use ConnectBrightbox
          b.use Call, IsCreated do |env, b2|
            if env[:result]
	      b2.use Call, IsRunning do |env2, b3|
	        if env2[:result]
		  b3.use MessageAlreadyCreated
		else
		  b3.use StartServer
		  b3.use MapCloudIp
		end
	      end
	    else
	      b2.use TimedProvision
	      b2.use SyncFolders
	      b2.use CreateServer
	      b2.use MapCloudIp
            end
          end
        end
      end

      def self.action_package
        Vagrant::Action::Builder.new.tap do |b|
	  b.use Unsupported
	end
      end

      class << self
	alias action_resume action_package
	alias action_suspend action_package
      end
        
      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectBrightbox, action_root.join("connect_brightbox")
      autoload :CreateServer, action_root.join("create_server")
      autoload :DeleteServer, action_root.join("delete_server")
      autoload :IsCreated, action_root.join("is_created")
      autoload :IsRunning, action_root.join("is_running")
      autoload :MessageAlreadyCreated, action_root.join("message_already_created")
      autoload :MessageNotCreated, action_root.join("message_not_created")
      autoload :MessageWillNotDestroy, action_root.join("message_will_not_destroy")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :SyncFolders, action_root.join("sync_folders")
      autoload :MapCloudIp, action_root.join("map_cloud_ip")
      autoload :ForcedHalt, action_root.join("forced_halt")
      autoload :StartServer, action_root.join("start_server")
      autoload :Unsupported, action_root.join("unsupported")
      autoload :TimedProvision, action_root.join("timed_provision")
    end
  end
end
