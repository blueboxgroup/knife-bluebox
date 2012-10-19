#
# Author:: Fletcher Nichol (<fnichol@bluebox.net>)
# Copyright:: Copyright (c) 2012 Blue Box Group
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

require File.expand_path('../../../../spec_helper', __FILE__)
require 'chef/knife/bluebox_base'

class Chef
  class Knife
    class DummyKnife < Knife
      include Knife::BlueboxBase
    end
  end
end

describe Chef::Knife::BlueboxBase do

  Chef::Knife::DummyKnife.load_deps

  before do
    create_testable_plugin!(Chef::Knife::DummyKnife)
  end

  describe "#bluebox_connection" do

    before do
      @before_config = Hash.new
      @before_config[:knife] = Hash.new
      [:bluebox_customer_id, :bluebox_api_key].each do |attr|
        @before_config[:knife][attr] = Chef::Config[:knife][attr]
      end

      Chef::Config[:knife][:bluebox_customer_id] = "007"
      Chef::Config[:knife][:bluebox_api_key] = "takeittothelimit"
    end

    after do
      [:bluebox_customer_id, :bluebox_api_key].each do |attr|
        Chef::Config[:knife][attr] = @before_config[:knife][attr]
      end
    end

    it "constructs a connection" do
      Fog::Compute.should_receive(:new).with({
        :provider => :bluebox,
        :bluebox_customer_id => "007",
        :bluebox_api_key => "takeittothelimit"
      })

      @knife.bluebox_connection
    end
  end
end
