#
# Author:: Joshua Yotty (<jyotty@bluebox.net>)
# Copyright:: Copyright (c) 2013 Blue Box Group
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
    class BlueboxLbList < Knife

      deps do
        require 'fog'
        require 'highline'
        require 'readline'
        require 'chef/json_compat'
      end

      banner "knife bluebox lb list"

      def h
        @highline ||= HighLine.new
      end

      def run
        blb = Fog::Bluebox::BLB.new(
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )

        blb.lb_applications.each do |application|
          lines = []

          lines << [ 'Application ID', 'Name', 'IP addresses'].map {|s| h.color(s, :bold)}
          lines << [ application.id, application.name, application.ip_v4, nil, nil, application.ip_v6 ]
          unless application.lb_services.empty?
            lines << [ 'Service ID', 'Service Type', 'Port'].map {|s| h.color(s, :bold)}
            application.lb_services.each do |service|
              lines << [ service.id, service.service_type, service.port.to_s ]
            end
          end
          lines.flatten!
          puts h.list(lines, :uneven_columns_across, 3)
        end

      end
    end
  end
end
