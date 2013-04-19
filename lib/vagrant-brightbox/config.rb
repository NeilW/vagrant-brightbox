require "vagrant"

module VagrantPlugins
  module Brightbox
    class Config < Vagrant.plugin("2", :config)
      # The API Client ID for accessing Brightbox.
      #
      # @return [String]
      attr_accessor :client_id

      # The secret access key for accessing Brightbox.
      #
      # @return [String]
      attr_accessor :secret

      # The URL to use as the API endpoint
      #
      # @return [String]
      attr_accessor :api_url

      # The URL to use as the API authentication endpoint
      #
      # @return [String]
      attr_accessor :auth_url

      # Email or user id for user based authentication
      #
      # @return [String]
      attr_accessor :username

      # Password for user based authentication
      #
      # @return [String]
      attr_accessor :password

      # The account id of the account on which operations should be performed
      # 
      # @return [String]
      attr_accessor :account


      # The ID of the Image to use.
      #
      # @return [String]
      attr_accessor :image_id

      # The zone to launch the server into. If nil, it will
      # use the default for your account.
      #
      # @return [String]
      attr_accessor :zone

      # The timeout to wait for a server to become ready
      #
      # @return [Fixnum]
      attr_accessor :server_build_timeout

      # The type of server to launch, such as "nano"
      #
      # @return [String]
      attr_accessor :server_type

      # The name of the server. This defaults to the name of the machine
      # defined by Vagrant (via `config.vm.define`), but can be overriden
      # here.
      attr_accessor :server_name

      # The name of the Brightbox region in which to create the server.
      #
      # @return [String]
      attr_accessor :region

      # The server groups to set on the server. This must
      # be a list of group IDs.
      #
      # @return [Array<String>]
      attr_accessor :server_groups

      # The user data string
      #
      # @return [String]
      attr_accessor :user_data

      def initialize(region_specific=false)
        @client_id      = UNSET_VALUE
        @secret  = UNSET_VALUE
        @api_url  = UNSET_VALUE
        @auth_url  = UNSET_VALUE
        @username  = UNSET_VALUE
        @password  = UNSET_VALUE
        @account  = UNSET_VALUE
        @image_id                = UNSET_VALUE
        @zone  = UNSET_VALUE
	@server_build_timeout = UNSET_VALUE
        @server_type      = UNSET_VALUE
	@server_name	  = UNSET_VALUE
        @region             = UNSET_VALUE
        @server_groups    = UNSET_VALUE
	@user_data	    = UNSET_VALUE

        # Internal state (prefix with __ so they aren't automatically
        # merged)
        @__compiled_region_configs = {}
        @__finalized = false
        @__region_config = {}
        @__region_specific = region_specific
      end

      # Allows region-specific overrides of any of the settings on this
      # configuration object. This allows the user to override things like
      # Image and keypair name for regions. Example:
      #
      #     brightbox.region_config "gb1" do |region|
      #       region.image_id = "img-umqoe"
      #     end
      #
      # @param [String] region The region name to configure.
      # @param [Hash] attributes Direct attributes to set on the configuration
      #   as a shortcut instead of specifying a full block.
      # @yield [config] Yields a new Brightbox configuration.
      def region_config(region, attributes=nil, &block)
        # Append the block to the list of region configs for that region.
        # We'll evaluate these upon finalization.
        @__region_config[region] ||= []

        # Append a block that sets attributes if we got one
        if attributes
          attr_block = lambda do |config|
            config.set_options(attributes)
          end

          @__region_config[region] << attr_block
        end

        # Append a block if we got one
        @__region_config[region] << block if block_given?
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      def merge(other)
        super.tap do |result|
          # Copy over the region specific flag. "True" is retained if either
          # has it.
          new_region_specific = other.instance_variable_get(:@__region_specific)
          result.instance_variable_set(
            :@__region_specific, new_region_specific || @__region_specific)

          # Go through all the region configs and prepend ours onto
          # theirs.
          new_region_config = other.instance_variable_get(:@__region_config)
          @__region_config.each do |key, value|
            new_region_config[key] ||= []
            new_region_config[key] = value + new_region_config[key]
          end

          # Set it
          result.instance_variable_set(:@__region_config, new_region_config)

        end
      end

      def finalize!
        # Default region is UK gb1. Because that's all there is at the moment!
        @region = "gb1" if @region == UNSET_VALUE

        # The server groups are empty by default.
        @server_groups = [] if @server_groups == UNSET_VALUE

        # Everything defaults to nil
        @client_id     = nil if @client_id     == UNSET_VALUE
        @secret = nil if @secret == UNSET_VALUE
        @auth_url = nil if @auth_url == UNSET_VALUE
        @api_url = nil if @api_url == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE
        @password = nil if @password == UNSET_VALUE
        @account = nil if @account == UNSET_VALUE
        @image_id = nil if @image_id == UNSET_VALUE
        @server_type = nil if @server_type == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @zone = nil if @zone == UNSET_VALUE

	# User data is nil by default
	@user_data = nil if @user_data == UNSET_VALUE

	# The default timeout is 120 seconds
	@server_build_timeout = 120 if @server_build_timeout == UNSET_VALUE

        # Compile our region specific configurations only within
        # NON-REGION-SPECIFIC configurations.
        if !@__region_specific
          @__region_config.each do |region, blocks|
            config = self.class.new(true).merge(self)

            # Execute the configuration for each block
            blocks.each { |b| b.call(config) }

            # The region name of the configuration always equals the
            # region config name:
            config.region = region

            # Finalize the configuration
            config.finalize!

            # Store it for retrieval
            @__compiled_region_configs[region] = config
          end
        end

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("vagrant_brightbox.config.region_required") if @region.nil?

	errors << I18n.t("vagrant_brightbox.config.region_invalid") unless valid_region?

        if @region && valid_region?
          # Get the configuration for the region we're using and validate only
          # that region.
          config = get_region_config(@region)

	  # Secret could be in fog config file. 
	  unless fog_config_file_exists?
	    errors << I18n.t("vagrant_brightbox.config.client_id_required") if \
	      config.client_id.nil?
	    errors << I18n.t("vagrant_brightbox.config.secret_required") if \
	      config.secret.nil?
	  end

        end

        { "Brightbox Provider" => errors }
      end

      def fog_config_file_exists?
        File.file?(File.join(ENV['HOME'], '.fog'))
      end

      def valid_region?
        return false unless @region =~ /gb1/
	@region == 'gb1' || !(@auth_url.nil? || @api_url.nil?)
      end

      # This gets the configuration for a specific region. It shouldn't
      # be called by the general public and is only used internally.
      def get_region_config(name)
        if !@__finalized
          raise "Configuration must be finalized before calling this method."
        end

        # Return the compiled region config
        @__compiled_region_configs[name] || self
      end
    end
  end
end
