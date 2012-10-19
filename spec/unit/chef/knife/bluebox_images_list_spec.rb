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
require 'chef/knife/bluebox_images_list'
require 'fog'
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
