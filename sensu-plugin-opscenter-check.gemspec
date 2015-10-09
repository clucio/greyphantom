lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require "sensu-plugins-opscenter/version"

Gem::Specification.new do |s|
  s.name        = 'sensu-plugins-opscenter'
  s.version     = SensuPluginsOpscenter::Version::VER_STRING
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Sensu Plugin DataStax Opscenter'
  s.description = 'Sensu check for collecting alert information from DataStax Opscenter'
  s.author      = 'Timothy Given'
  s.email       = 'tagiven@gmail.com'
  s.homepage    = ''
  s.files       = [
    'bin/check-alerts.rb',
    'lib/sensu-plugins-opscenter.rb',
    'lib/sensu-plugins-opscenter/version.rb'
  ]

  s.add_runtime_dependency 'json', '~> 1.0', '>= 1.0.0'
  s.add_runtime_dependency 'rest-client', '~> 1.8', '>= 1.8.0'
  s.add_runtime_dependency 'sensu-plugin', '~> 1.2', '>= 1.2.0'

end
