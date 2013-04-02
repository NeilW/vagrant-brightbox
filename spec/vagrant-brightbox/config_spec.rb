require "vagrant-brightbox/config"

describe VagrantPlugins::Brightbox::Config do
  let(:instance) { described_class.new }

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    # Connection
    its("client_id")     { should be_nil }
    its("secret") { should be_nil }
    its("auth_url") { should be_nil }
    its("api_url") { should be_nil }
    its("username") { should be_nil }
    its("password") { should be_nil }
    its("account") { should be_nil }

    # Server
    its("image_id")               { should be_nil }
    its("zone") { should be_nil }
    its("server_type")     { should be_nil }
    its("server_name")     { should be_nil }
    its("region")            { should == "gb1" }
    its("server_groups")   { should == [] }

    # Access
    its("ssh_private_key_path") { should be_nil }
    its("ssh_username")      { should be_nil }
  end

  describe "overriding defaults" do
    [:client_id, :secret, :auth_url, :api_url, :username, :password, :account,
     :image_id, :zone, :server_type, :server_name, :region, :server_groups,
      :ssh_private_key_path, :ssh_username].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end
  end

  describe "region config" do
    let(:config_client_id)     { "foo" }
    let(:config_secret) { "foo" }
    let(:config_auth_url) { "foo" }
    let(:config_api_url) { "foo" }
    let(:config_username) { "foo" }
    let(:config_password) { "foo" }
    let(:config_account) { "foo" }

    let(:config_image_id)               { "foo" }
    let(:config_server_type)     { "foo" }
    let(:config_server_name)     { "foo" }
    let(:config_server_groups)     { ["foo", "bar"] }
    let(:config_zone)     { "foo" }
    let(:config_region)            { "foo" }

    def set_test_values(instance)
      instance.client_id       = config_client_id
      instance.secret          = config_secret
      instance.auth_url	       = config_auth_url
      instance.api_url         = config_api_url
      instance.username        = config_username
      instance.password        = config_password
      instance.account	       = config_account

      instance.image_id        = config_image_id
      instance.server_type     = config_server_type
      instance.server_name     = config_server_name
      instance.region          = config_region
      instance.zone	       = config_zone
      instance.server_groups   = config_server_groups
    end

    it "should raise an exception if not finalized" do
      expect { instance.get_region_config("gb1") }.
        to raise_error
    end

    context "with no specific config set" do
      subject do
        # Set the values on the top-level object
        set_test_values(instance)

        # Finalize so we can get the region config
        instance.finalize!

        # Get a lower level region
        instance.get_region_config("gb1")
      end

      its("client_id")     { should == config_client_id }
      its("secret") { should == config_secret }
      its("auth_url") { should == config_auth_url }
      its("api_url") { should == config_api_url }
      its("username") { should == config_username }
      its("password") { should == config_password }
      its("account") { should == config_account }

      its("image_id")               { should == config_image_id }
      its("server_name")     { should == config_server_name }
      its("server_type")     { should == config_server_type }
      its("region")            { should == config_region }
      its("zone")            { should == config_zone }
      its("server_groups")            { should == config_server_groups }
    end

    context "with a specific config set" do
      let(:region_name) { "hashi-region" }

      subject do
        # Set the values on a specific region
        instance.region_config region_name do |config|
          set_test_values(config)
        end

        # Finalize so we can get the region config
        instance.finalize!

        # Get the region
        instance.get_region_config(region_name)
      end

      its("client_id")     { should == config_client_id }
      its("secret") { should == config_secret }
      its("auth_url") { should == config_auth_url }
      its("api_url") { should == config_api_url }
      its("username") { should == config_username }
      its("password") { should == config_password }
      its("account") { should == config_account }

      its("image_id")               { should == config_image_id }
      its("server_name")     { should == config_server_name }
      its("server_type")     { should == config_server_type }
      its("zone")            { should == config_zone }
      its("server_groups")            { should == config_server_groups }
    end

    describe "inheritance of parent config" do
      let(:region_name) { "hashi-region" }

      subject do
        # Set the values on a specific region
        instance.region_config region_name do |config|
          config.image_id = "child"
        end

        # Set some top-level values
        instance.client_id = "parent"
        instance.image_id = "parent"

        # Finalize and get the region
        instance.finalize!
        instance.get_region_config(region_name)
      end

      its("client_id") { should == "parent" }
      its("image_id")           { should == "child" }
    end

    describe "shortcut configuration" do
      subject do
        # Use the shortcut configuration to set some values
        instance.region_config "gb1", :image_id => "child"
        instance.finalize!
        instance.get_region_config("gb1")
      end

      its("image_id") { should == "child" }
    end

  end
end
