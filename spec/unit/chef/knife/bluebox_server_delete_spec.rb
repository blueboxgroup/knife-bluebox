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

require File.expand_path('../../../../spec_helper', __FILE__)
require 'chef/knife/bluebox_server_delete'
require 'fog'

describe Chef::Knife::BlueboxServerDelete do

  described_class.load_deps

  before do
    create_testable_plugin!
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
      connection.stub(:destroy_block).with("uuid-2") { stub(:status => 200) }
      @knife.name_args = ["ralph.org"]
      @knife.ui.stub(:confirm) { true }
    end

    it "confirms deletion with the user" do
      pending
      @knife.ui.should_receive(:confirm).with(/ralph\.org/)

      capture_stdout { @knife.run }
    end

    it "destroys the block" do
      pending
      connection.should_receive(:destroy_block).with("uuid-2")

      capture_stdout { @knife.run }
    end

    it "exits if the hostname does not exist in the server list" do
      @knife.name_args = ["no-way-jose"]

      expect { @knife.run }.to raise_error SystemExit
    end

    shared_examples "a reported failure" do
      it "outputs an error message" do
        pending
        out = capture_stdout do
          begin
            @knife.run
          rescue SystemExit
            # terrible, but we want to swallow the exit for the moment
          end
        end.string

        out.should match(/there was a problem/i)
      end

      it "exits with nonzero status" do
        expect { capture_stdout { @knife.run } }.to raise_error(SystemExit)
      end
    end

    context "when an Excon exception is raised" do
      before do
        connection.stub(:destroy_block).with("uuid-2") { stub(:status => 500) }
      end

      it_behaves_like "a reported failure"
    end

    context "when a non-200 status response is returned" do
      before do
        connection.stub(:destroy_block) {
          raise Excon::Errors::UnprocessableEntity.new("oops")
        }
      end

      it_behaves_like "a reported failure"
    end
  end
end
