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
      end

      banner "knife bluebox server delete BLOCK-HOSTNAME"

      def h
        @highline ||= HighLine.new
      end

      def run
        bluebox = Fog::Compute::Bluebox.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        # Build hash of hostname => id
        servers = bluebox.servers.inject({}) { |h,f| h[f.hostname] = f.id; h }

        unless servers.has_key?(@name_args[0])
          ui.error("Can't find a block named #{@name_args[0]}")
          exit 1
        end

        confirm(h.color("Do you really want to delete block UUID #{servers[@name_args[0]]} with hostname #{@name_args[0]}", :green))

        begin
          response = bluebox.destroy_block(servers[@name_args[0]])
          if response.status == 200
            puts "\n\n#{h.color("Successfully destroyed #{@name_args[0]}", :green)}"
          else
            puts "\n\n#{h.color("There was a problem destroying #{@name_args[0]}. Please check Box Panel.", :red)}"
            exit 1
          end
        rescue Excon::Errors::UnprocessableEntity
          puts "\n\n#{h.color("There was a problem destroying #{@name_args[0]}. Please check Box Panel.", :red)}"
        end
      end
    end
  end
end
