# `knife bluebox`
This is the official Opscode Knife plugin for {Blue Box}[http://www.bluebox.net].
This plugin gives knife the ability to create, bootstrap, and manage Blue Box
servers and load balancers.

## Installation
This plugin is distributed as a Ruby Gem. To install it, run:
    gem install knife-bluebox

## Configuration
Set the following environmental variables in the right dotfile (typically `.profile`, `.bash_profile`, or `.zshrc`):

```
export BLUEBOX_API_KEY="YourAPIKey"              # should match /[a-f0-9]+/
export BLUEBOX_CUSTOMER_ID="YourCustomerNumber"  # should match /d+/
```

Then your chef repository's `.chef/knife.rb`, set

```ruby
knife[:bluebox_customer_id] = ENV['BLUEBOX_CUSTOMER_ID']
knife[:bluebox_api_key]     = ENV['BLUEBOX_API_KEY']
knife[:identity_file]       = "#{ENV['HOME']}/.ssh/id_rsa"
knife[:public_identity_file] = "#{ENV['HOME']}/.ssh/id_rsa.pub"
```

## Usage
```
knife bluebox flavor list
knife bluebox image create [uuid]
knife bluebox image delete [UUID]
knife bluebox image list
knife bluebox lb list
knife bluebox server create [RUN LIST...] (options)
knife bluebox server delete BLOCK-HOSTNAME
knife bluebox server list (options)
```

You will need to run knife from within your chef-repo to have the knife.rb config take effect.
