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
    class BlueboxServerList < Knife

      deps do
        require 'fog'
        require 'terminal-table'
        require 'readline'
        require 'chef/json_compat'
      end

      banner "knife bluebox server list (options)"

      def run
        bluebox = Fog::Compute::Bluebox.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        # Make hash of flavor id => name and image id => name
        flavors = bluebox.flavors.inject({}) { |h,f| h[f.id] = f.description; h }
        images  = bluebox.images.inject({}) { |h,i| h[i.id] = i.description; h }

        table = Terminal::Table.new do |t|
          
          t << [ 'ID', 'Hostname', 'IP Address', 'Memory', 'CPU']
          t << :separator
          
          bluebox.servers.each do |server|

            t << Array.new.tap do |row|
              
              # ID
              row << server.id.to_s

              # Hostname
              row << server.hostname

              # IP Address
              if server.ips[0] && server.ips[0]["address"]
                row << server.ips[0]["address"]
              else
                row << ""
              end

              # Memory
              row << String(server.memory)          

              # Cpu
              row << String(server.cpu)              
            end
          end
        end
        
        puts table

      end
    end
  end
end
