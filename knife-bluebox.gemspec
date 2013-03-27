$:.unshift(File.dirname(__FILE__) + '/lib')
require 'knife-bluebox/version'

Gem::Specification.new do |s|
  s.name              = 'knife-bluebox'
  s.version           = KnifeBlueBox::VERSION
  s.platform          = Gem::Platform::RUBY
  s.has_rdoc          = true
  s.extra_rdoc_files  = ["LICENSE"]
  s.summary           = "Chef knife plugin for Blue Box"
  s.description       = s.summary
  s.authors           = ["Lee Huffman","Jesse Proudman"]
  s.email             = "support@bluebox.net"
  s.homepage          = "https://github.com/blueboxgroup/knife-bluebox"

  s.add_dependency "chef", ">= 0.10.10"
  s.add_dependency "fog", "~> 1.10.0"
  s.add_dependency "tabularize", '~> 0.2.9'
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md) + Dir.glob("lib/**/*")
end

