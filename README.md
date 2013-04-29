# Vagrant Brightbox Provider

This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds a [Brightbox](http://brightbox.com/)
provider to Vagrant, allowing Vagrant to control and provision servers in
the Brightbox Cloud.

**Note:** This plugin requires Vagrant 1.2+,

## Features

* Boot Brightbox Cloud servers.
* SSH into the servers.
* Provision the servers with any built-in Vagrant provisioner.
* Minimal synced folder support via `rsync`.
* Define region-specific configurations so Vagrant can manage servers
  in multiple regions.

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `brightbox` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-brightbox
...
$ vagrant up --provider=brightbox
...
```

Of course prior to doing this, you'll need to obtain a Brightbox-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), select the Brightbox
Cloud image you want to use and note the id.  You can find these using
the Brightbox CLI or the Cloud GUI in the normal way, or you can view the
[Vagrant image page](http://docs.brightbox.com/vagrant/images).

Then add your chosen box to your vagrant installation using the
`config.vm.box` tag from your Vagrantfile, e.g.

```
$ vagrant box add precise32 http://docs.brightbox.com/vagrant/img-mvunm.box
```

If you have your `~/.fog` setup to access Brightbox then you can now
bring up your configuration on Brightbox Cloud with:

```
$ vagrant up --provider=brightbox
```

## Generic Setup

If you don't want to be adding new box files for every type of image on
Brightbox Cloud you can shift the configuration into the Vagrantfile by
using the `dummy.box` Vagrant box file which has no preconfigured defaults.

First add the dummy box to your vagrant installation.

```
$ vagrant box add dummy http://docs.brightbox.com/vagrant/dummy.box
```

Then make a Vagrantfile that looks like the following, filling in
your information where necessary along with your choice of image id

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.vm.provider :brightbox do |brightbox, override|
    brightbox.client_id = "YOUR API CLIENT ID"
    brightbox.secret = "YOUR API SECRET"

    brightbox.image_id = "img-q6gc8"

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = "PATH TO YOUR PRIVATE KEY"
  end
end
```

Finally run `vagrant up --provider=brightbox` to build your setup on Brightbox Cloud.

This will start an Ubuntu 12.04 server in the gb1 region within
your account. And assuming your SSH information was filled in properly
within your Vagrantfile, SSH and provisioning will work as well.

Instead of having to add your client credentials to each Vagrantfile
we can put them in the Fog configuration file. Create a new
file at `~/.fog` and add the following:

```
:default:
  :brightbox_client_id: "your_api_client_id"
  :brightbox_secret: "your_secret"
```

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `brightbox` boxes. You can view an example box in
the [example_box/ directory](https://github.com/NeilW/vagrant-brightbox/tree/master/example_box).

That directory also contains instructions on how to build a box.

The box format is the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Box Format Dowloadable Images

You can view the [list of current Vagrant box
files](http://docs.brightbox.com/vagrant) on the Brightbox documentation
site.

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `client_id` - The api access key for accessing Brightbox in the form
'cli-xxxxx'
* `secret` - The api secret access code for accessing Brightbox
* `image_id` - The image id to boot, in the form 'img-xxxxx'
* `zone` - The zone within the region to launch
  the server. If nil, it will use the default for this account. 
* `server_type` - The type of server, such as "nano"
* `region` - The region to start the server in, such as "gb1"
* `security_groups` - An array of security groups for the server.
* `server_build_timeout` - The number of seconds to wait for the instance
to become ready on Brightbox Cloud. Defaults to 120 seconds.

If you are the collaborator on a number of accounts you can specify
which one you want by setting the following options:

* `username` - User id in the form 'usr-xxxxx'
* `password` - The password for the user id
* `account` - Create servers in the context of this account - in the form
'acc-xxxxx'

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :brightbox do |brightbox|
    brightbox.client_id = "cli-fooxx"
    brightbox.secret = "barfoobarfoobar"
  end
end
```

In addition to the above top-level configs, you can use the `region_config`
method to specify region-specific overrides within your Vagrantfile. Note
that the top-level `region` config must always be specified to choose which
region you want to actually use, however. This looks like this:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :brightbox do |brightbox|
    brightbox.client_id = "foo"
    brightbox.secret = "bar"
    brightbox.region = "gb1"

    # Simply region config
    brightbox.region_config "gb1", :image_id => "img-mvunm"

    # More comprehensive region config
    brightbox.region_config "gb1" do |region|
      region.image_id = "img-mvunm"
    end
  end
end
```

The region-specific configurations will override the top-level
configurations when that region is used. They otherwise inherit
the top-level configurations, as you would probably expect.

## Networks

By default each brightbox is created and mapped to a cloud ip so that
you can access it over the public network.

However this can exhaust your allocation of cloud ips if you have several servers. Therefore a couple of networking options are supported.

```ruby
  # Switch off cloud ip mapping and access servers over the IPv4 private
  # network - useful if you are running Vagrant from another cloud server.
  config.vm.network :private_network

  # Switch off cloud ip mapping and access servers over IPv6.
  config.vm.network :public_network, ipv6: true
```

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the Brightbox provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Other Examples

### User data

You can specify user data for the server being booted.

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "brightbox" do |brightbox|
    # Option 1: a single string
    brightbox.user_data = "#!/bin/bash\necho 'got user data' > /tmp/user_data.log\necho"

    # Option 2: use a file
    brightbox.user_data = File.read("user_data.txt")
  end
end
```

## Development

To work on the `vagrant-brightbox` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it:

```ruby
Vagrant.require_plugin "vagrant-brightbox"

Vagrant.configure("2") do |config|
  #Config here
end
```

and then use bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=brightbox
```
