#
# Author:: Fletcher Nichol (<fnichol@bluebox.net>)
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
    module BlueboxBase

      def self.included(included_class)
        included_class.class_eval do

          deps do
            require 'fog'
          end
        end
      end

      def bluebox_connection
        @bluebox_connection ||= Fog::Compute.new(
          :provider => :bluebox,
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id],
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key]
        )
      end
    end
  end
end
