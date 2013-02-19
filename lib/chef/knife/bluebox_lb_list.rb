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

        lines = []

        blb.lb_applications.each do |application|
          lines << [ h.color('Application ID', :bold), h.color('Name', :bold), h.color('IPv4 address', :bold), h.color('IPv6 addr', :bold)]
          lines << [ application.id, application.name, application.ip_v4, application.ip_v6 ]
          unless application.services.empty?
            lines << [ h.color('Service ID', :bold), h.color('Service Type', :bold), h.color('Port', :bold), h.color('Private', :bold) ]
            application.services.each do |service|
              lines << [ service['id'], service['service_type'], service['port'].to_s, service['private'].to_s ]
            end
          end
        end
        lines.flatten!
        puts h.list(lines, :columns_across, 4)

      end
    end
  end
end
