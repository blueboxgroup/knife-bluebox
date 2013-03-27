# `knife bluebox`
This is the official Opscode Knife plugin for [Blue Box](http://www.bluebox.net).
This plugin gives knife the ability to create, bootstrap, and manage Blue Box
servers.

## Installation
This plugin is distributed as a Ruby Gem. To install it, run:

    gem install knife-bluebox

## Configuration
Set the following environmental variables in the right dotfile (typically `.profile`, `.bash_profile`, or `.zshrc`):

```
export BLUEBOX_API_KEY="YourAPIKey"              # should match /[a-f0-9]+/
export BLUEBOX_CUSTOMER_ID="YourCustomerNumber"  # should match /d+/
```

Then in your chef repository's `.chef/knife.rb`, set

```ruby
knife[:bluebox_customer_id]  = ENV['BLUEBOX_CUSTOMER_ID']
knife[:bluebox_api_key]      = ENV['BLUEBOX_API_KEY']
knife[:identity_file]        = "#{ENV['HOME']}/.ssh/id_rsa"
knife[:public_identity_file] = "#{ENV['HOME']}/.ssh/id_rsa.pub"
```

You will need to run knife from within your chef repo to have the knife.rb config take effect.

## Usage and subcommands
For a complete list of options for each command, use `knife bluebox SUBCOMMAND ACTION --help`.

### knife bluebox flavor list
Show available block types and associated UUIDs.

### knife bluebox image \[create|delete|list\] \[options\]
Manipulate and display stored block images.
* `knife bluebox create UUID` creates a new machine image from the server specified by `UUID`.
  * `--public` will make the machine image public for other blocks users to deploy from.
  * `--description` provides a description for the image. Default is machine hostname and
    timestamp.

### knife bluebox lb list
Show list of Blocks Load Balancer applications and each application's load balanced services.

### knife bluebox server create \[RUN LIST...\] (options)
Create a new block instance.

### knife bluebox server delete HOSTNAME
Delete block instance specified by _HOSTNAME_.

### knife bluebox server list (options)
List all blocks currently running on the account.
