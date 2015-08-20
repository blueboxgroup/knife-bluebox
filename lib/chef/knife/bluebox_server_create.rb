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

      option :location,
        :short => "-L LOCATION",
        :long => "--location LOCATION",
        :description => "The location UUID of the server",
        :default => "37c2bd9a-3e81-46c9-b6e2-db44a25cc675"

      option :username,
        :short => "-U KEY",
        :long => "--username username",
        :description => "Username on new server",
        :default => "deploy"

      option :password,
        :short => "-P password",
        :long => "--password password",
        :description => "User password on new server."

      option :disable_bootstrap,
        :long => "--disable-bootstrap",
        :description => "Disables the bootstrapping process.",
        :boolean => true

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template",
        :default => "chef-full"

      option :identity_file,
        :short => "-I IDENTITY_FILE",
        :long => "--identity-file PRIVATE_IDENTITY_FILE",
        :description => "The private SSH identity file used for authentication to the new server"

      option :public_identity_file,
        :short => "-B PUBLIC_IDENTITY_FILE",
        :long => "--public-identity-file PUBLIC_IDENTITY_FILE",
        :description => "The public SSH identity file used for authentication to new server"

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

        public_key = config[:public_identity_file] || Chef::Config[:knife][:public_identity_file]
        identity_file = config[:identity_file] || Chef::Config[:knife][:identity_file]

        if config[:password].nil?

          if !public_key
            ui.error('Since no password was provided a public_identity_file needs to be set.')
            exit 1
          end

          if !identity_file
            ui.error('Since no password was provided an identity_file needs to be set.')
            exit 1
          end
        end

        bluebox = Fog::Compute::Bluebox.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        flavors = bluebox.flavors.inject({}) { |h,f| h[f.id] = f.description; h }
        images  = bluebox.images.inject({}) { |h,i| h[i.id] = i.description; h }

        puts "#{h.color("Deploying a new Blue Box Block...", :green)}\n\n"

        image_id = Chef::Config[:knife][:image] || config[:image]
        location_id = Chef::Config[:knife][:location] || config[:location]

        server = bluebox.servers.new(
          :flavor_id => Chef::Config[:knife][:flavor] || config[:flavor],
          :image_id => image_id,
          :location_id => location_id,
          :hostname => config[:chef_node_name],
          :username => Chef::Config[:knife][:username] || config[:username],
          :password => config[:password],
          :public_key => public_key.nil? ? nil : File.read(public_key),
          :lb_applications => Chef::Config[:knife][:load_balancer] || config[:load_balancer]
        )

        begin
          response = server.save
        rescue Fog::Compute::Bluebox::NotFound
          puts "#{h.color("Could not locate an image with uuid #{image_id}.\n", :red)}"
          exit 1
        end

        # Wait for the server to start
        begin

          # Make sure we could properly queue the server for creation on BBG.
          #
          unless %w(queued building).include?(server.state)
            raise Fog::Compute::Bluebox::BlockInstantiationError
          end

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
              bootstrap.config[:ssh_password] = config[:password]
              bootstrap.config[:ssh_user] = config[:username]
              bootstrap.config[:identity_file] = identity_file
              bootstrap.config[:chef_node_name] = config[:chef_node_name] || server.hostname
              bootstrap.config[:use_sudo] = true
              bootstrap.config[:distro] = config[:distro]
              bootstrap.run
              print "\n#{h.color("Finished bootstrapping #{server.hostname}\n\n", :green)}"
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
        candidate = @name_args.first
        return candidate if /[\s,]+/ !~ candidate
        candidate.split(/[\s,]+/)
      end

    end
  end
end
