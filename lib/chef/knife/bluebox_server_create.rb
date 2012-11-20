#
# Author:: Jesse Proudman (<jesse.proudman@blueboxgrp.com>)
# Copyright:: Copyright (c) 2010 Blue Box Group
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'

class Chef
  class Knife
    class BlueboxServerCreate < Knife

      deps do
        require 'fog'
        require 'readline'
        require 'highline'
        require 'net/ssh/multi'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife bluebox server create [RUN LIST...] (options)"

      option :flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server",
        :default => "94fd37a7-2606-47f7-84d5-9000deda52ae"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :image,
        :short => "-i IMAGE",
        :long => "--image IMAGE",
        :description => "The image of the server",
        :default => "a8f05200-7638-47d1-8282-2474ef57c4c3"

      option :username,
        :short => "-U KEY",
        :long => "--username username",
        :description => "Username on new server",
        :default => "deploy"

      option :password,
        :short => "-P password",
        :long => "--password password",
        :description => "User password on new server.",
        :default => ""

      option :disable_bootstrap,
        :long => "--disable-bootstrap",
        :description => "Disables the bootstrapping process.",
        :boolean => true

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "ubuntu10.04-gems"

      option :identity_file,
        :short => "-I IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :load_balancer,
        :short => "-b LB",
        :long => "--load_balancer LB",
        :description => "Adds server to the specified load balanced application."

      option :block_startup_timeout,
        :long => "--block_startup_timeout TIME",
        :description => "Amount of time fog should wait before aborting server deployment.",
        :default => 10 * 60

      def h
        @highline ||= HighLine.new
      end

      def run
        $stdout.sync = true

        if Chef::Config[:knife][:identity_file].nil? && config[:identity_file].nil?
          ui.error('You have not provided a SSH identity file. This is required to create a Blue Box server.')
          exit 1
        elsif Chef::Config[:knife][:identity_file]
          public_key = File.read(Chef::Config[:knife][:identity_file]).chomp
        else public_key = File.read(config[:identity_file]).chomp
        end

        bluebox = Fog::Compute::Bluebox.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        flavors = bluebox.flavors.inject({}) { |h,f| h[f.id] = f.description; h }
        images  = bluebox.images.inject({}) { |h,i| h[i.id] = i.description; h }

        puts "#{h.color("Deploying a new Blue Box Block...", :green)}\n\n"

        server = bluebox.servers.new(
          :flavor_id => Chef::Config[:knife][:flavor] || config[:flavor],
          :image_id => Chef::Config[:knife][:image] || config[:image],
          :hostname => config[:chef_node_name],
          :username => Chef::Config[:knife][:username] || config[:username],
          :password => config[:password],
          :public_key => public_key,
          :lb_applications => Chef::Config[:knife][:load_balancer] || config[:load_balancer]
        )

        response = server.save

        # Wait for the server to start
        begin

          # Make sure we could properly queue the server for creation on BBG.
          raise Fog::Compute::Bluebox::BlockInstantiationError if server.state != "queued"
          puts "#{h.color("Hostname", :cyan)}: #{server.hostname}"
          puts "#{h.color("Server Status", :cyan)}: #{server.state.capitalize}"
          puts "#{h.color("Flavor", :cyan)}: #{flavors[server.flavor_id]}"
          puts "#{h.color("Image", :cyan)}: #{images[server.image_id]}"
          puts "#{h.color("IP Address", :cyan)}: #{server.ips[0]['address']}"
          puts "#{h.color("Load Balanced Applications", :cyan)}: #{server.lb_applications.collect { |x| x['lb_application_name'] }.join(", ")}" unless server.lb_applications.empty?

          # The server was succesfully queued... Now wait for it to spin up...
          print "\n#{h.color("Requesting status of #{server.hostname}\n", :magenta)}"

          # Define a timeout and ensure the block starts up in the specified amount of time:
          # ready? will raise Fog::Bluebox::Compute::BlockInstantiationError if block creation fails.
          unless server.wait_for(config[:block_startup_timeout]){ print "."; STDOUT.flush; ready? }

            # The server wasn't started in specified timeout ... Send a destroy call to make sure it doesn't spin up on us later.
            server.destroy
            raise Fog::Compute::Bluebox::BlockInstantiationError, "BBG server not available after #{config[:block_startup_timeout]} seconds."

          else
            print "\n\n#{h.color("BBG Server startup succesful.  Accessible at #{server.hostname}\n", :green)}"

            # Make sure we should be bootstrapping.
            if config[:disable_bootstrap]
              puts "\n\n#{h.color("Boostrapping disabled per command line inputs.  Exiting here.", :green)}"
              exit 0
            end

            # Bootstrap away!
            print "\n\n#{h.color("Starting bootstrapping process...", :green)}\n"

            # Connect via SSH and make this all happen.
            begin
              bootstrap = Chef::Knife::Bootstrap.new
              bootstrap.name_args = [ server.ips[0]['address'] ]
              bootstrap.config[:run_list] = run_list
              bootstrap.config[:password] = password unless config[:password].empty?
              bootstrap.config[:ssh_user] = config[:username]
              bootstrap.config[:identity_file] = config[:identity_file]
              bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.hostname
              bootstrap.config[:use_sudo] = true
              bootstrap.config[:distro] = config[:distro]
              bootstrap.run
            rescue Errno::ECONNREFUSED
              puts h.color("Connection refused on SSH, retrying - CTRL-C to abort")
              sleep 1
              retry
            rescue Errno::ETIMEDOUT
              puts h.color("Connection timed out on SSH, retrying - CTRL-C to abort")
              sleep 1
              retry
            end

          end

        rescue Fog::Compute::Bluebox::BlockInstantiationError => e

          puts "\n\n#{h.color("Encountered error starting up BBG block. Auto destroy called.  Please try again.", :red)}"

        end
      end

      def run_list
        @name_args.first.split(/[\s,]+/)
      end

    end
  end
end
