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
require 'chef/knife/bluebox_server_list'
require 'fog'
Chef::Knife::BlueboxServerList.load_deps

describe Chef::Knife::BlueboxServerList do

  def ips(primary_ip)
    [ { "address" => primary_ip }, { "address" => "i:am:an:ip:v:6:addr" } ]
  end

  before do
    Chef::Log.logger = Logger.new(StringIO.new)
    @knife = Chef::Knife::BlueboxServerList.new
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout) { @stdout }
    @knife.ui.stub(:msg)
    @stderr = StringIO.new
    @knife.ui.stub!(:stderr) { @stderr }
  end

  let(:connection)  { mock(Fog::Compute::Bluebox) }

  let(:servers) do
    [
      stub(:id => "uuid-8", :hostname => "wiggum.com", :ips => ips("172.0.1.2")),
      stub(:id => "uuid-2", :hostname => "ralph.org", :ips => ips("172.0.3.4"))
    ]
  end

  describe "#run" do

    before do
      @knife.stub(:bluebox_connection)  { connection }
      connection.stub(:servers)  { servers }
    end

    it "outputs server data" do
      out = capture_stdout do
        @knife.run
      end.string

      out.should match(/uuid-8\s+wiggum\.com\s+172\.0\.1\.2/)
      out.should match(/uuid-2\s+ralph\.org\s+172\.0\.3\.4/)
    end
  end
end
