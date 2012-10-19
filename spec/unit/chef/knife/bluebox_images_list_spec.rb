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

require 'chef/knife/bluebox_images_list'
Chef::Knife::BlueboxImagesList.load_deps

describe Chef::Knife::BlueboxImagesList do

  before do
    Chef::Log.logger = Logger.new(StringIO.new)
    @knife = Chef::Knife::BlueboxImagesList.new
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout) { @stdout }
    @knife.ui.stub(:msg)
    @stderr = StringIO.new
    @knife.ui.stub!(:stderr) { @stderr }
  end

  let(:connection)  { mock(Fog::Compute::Bluebox) }

  let(:images) do
    [
      stub(:id => "uuid-9", :description => "NightmareOS"),
      stub(:id => "uuid-1", :description => "DreamOS")
    ]
  end

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
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

  describe "#run" do

    before do
      @knife.stub(:bluebox_connection)  { connection }
      connection.stub(:images)  { images }
    end

    it "outputs image data" do
      out = capture_stdout do
        @knife.run
      end.string

      out.should match(/uuid-9\s+NightmareOS/)
      out.should match(/uuid-1\s+DreamOS/)
    end
  end
end
