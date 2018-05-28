$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
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

  s.add_runtime_dependency 'ruby-progressbar', '~> 1.1'
  s.add_runtime_dependency 'netaddr', '~> 1.5'
  # Adding awesome_print because it's just awesome to read XML
  s.add_runtime_dependency 'awesome_print', '~> 1.2'
  s.add_runtime_dependency 'terminal-table', '~> 1.4'
  s.add_runtime_dependency 'nokogiri', '~> 1.8'

  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec-core', '~> 2.12'
  s.add_development_dependency 'rspec-expectations', '~> 2.12'
  s.add_development_dependency 'rspec-mocks', '~> 2.12'

  s.files = `git ls-files`.split($/)
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_path = 'lib'
end
