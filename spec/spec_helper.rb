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

module Helpers

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    return out
  ensure
    $stdout = STDOUT
  end

  def create_testable_plugin!(klass = described_class)
    Chef::Log.logger = Logger.new(StringIO.new)
    @knife = klass.new
    @stdout = StringIO.new
    @knife.ui.stub!(:stdout) { @stdout }
    @knife.ui.stub(:msg)
    @stderr = StringIO.new
    @knife.ui.stub!(:stderr) { @stderr }
  end
end

RSpec.configure do |config|
  config.include Helpers
end
