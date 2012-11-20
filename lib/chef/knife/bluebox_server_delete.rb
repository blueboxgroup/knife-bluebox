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
    class BlueboxServerDelete < Knife

      deps do
        require 'fog'
        require 'highline'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/node'
        require 'chef/api_client'
      end

      banner "knife bluebox server delete BLOCK-HOSTNAME"

      def run
        bluebox = Fog::Compute::Bluebox.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        server_to_remove = @name_args[0]

        # Build hash of hostname => id
        servers = bluebox.servers.inject({}) { |h,f| h[f.hostname] = f.id; h }

        unless servers.has_key?(server_to_remove)
          ui.error("Can't find a block named #{server_to_remove}")
          exit 1
        end

        # remove the block instance
        ui.confirm("Do you really want to delete block UUID #{servers[server_to_remove]} with hostname #{server_to_remove}")
        begin
          response = bluebox.destroy_block(servers[server_to_remove])
          if response.status == 200
            ui.msg(green("Successfully destroyed #{server_to_remove}"))
          else
            ui.msg(red("There was a problem destroying #{server_to_remove}. Please check Box Panel."))
            exit 1
          end
        rescue Excon::Errors::UnprocessableEntity
          ui.msg(red("There was a problem destroying #{server_to_remove}. Please check Box Panel."))
        end

        # remove chef client and node
        chef_name = server_to_remove.split(".").first
        ui.confirm("Do you wish to remove the #{chef_name} node and client objects from the chef server?")
        remove_node(chef_name)
        remove_client(chef_name)
      end

      def remove_node(node)
        begin
          object = Chef::Node.load(node)
          object.destroy
          ui.msg(green("#{node} node removed from chef server"))
        rescue Net::HTTPServerException
          ui.msg(green("The chef server did not have a #{node} node object"))
        end
      end

      def remove_client(client)
        begin
          object = Chef::ApiClient.load(client)
          object.destroy
          ui.msg(green("#{client} client removed from chef server"))
        rescue Net::HTTPServerException
          ui.msg(green("The chef server did not have a #{client} client object"))
        end
      end

      def highline
        @highline ||= HighLine.new
      end

      def green(text)
        "#{highline.color(text, :green)}"
      end

      def red(text)
        "#{highline.color(text, :red)}"
      end

    end
  end
end
