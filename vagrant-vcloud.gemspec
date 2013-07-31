$:.unshift File.expand_path('../lib', __FILE__)
require 'vagrant-vcloud/version'

Gem::Specification.new do |s|
  s.name = 'vagrant-vcloud'
  s.version = VagrantPlugins::VCloud::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Fabio Rapposelli', 'Timo Sugliani']
  s.email = ['fabio@rapposelli.org', 'timo.sugliani@gmail.com']
  s.homepage = 'https://github.com/frapposelli/vagrant-vcloud'
  s.license = 'MIT'
  s.summary = 'VMware vCloud Director® provider'
  s.description = 'Enables Vagrant to manage machines with VMware vCloud Director®.'
  
  s.add_runtime_dependency 'i18n', '~> 0.6.4'
  s.add_runtime_dependency 'ruby-unison' # github.com/ytaka/ruby-unison
  s.add_runtime_dependency 'log4r'
  s.add_runtime_dependency 'awesome_print'
  s.add_runtime_dependency 'nokogiri'
  s.add_runtime_dependency 'rest-client'
  s.add_runtime_dependency 'httpclient'
  s.add_runtime_dependency 'ruby-progressbar'

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-core", "~> 2.12.2"
  s.add_development_dependency "rspec-expectations", "~> 2.12.1"
  s.add_development_dependency "rspec-mocks", "~> 2.12.1"
  
  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_path = 'lib'
end
