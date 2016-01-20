lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require "sensu-plugins-ambari/version"

Gem::Specification.new do |s|
  s.name        = 'sensu-plugins-ambari'
  s.version     = SensuPluginsAmbari::Version::VER_STRING
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = 'Sensu Plugin Ambari'
  s.description = 'Sensu check for collecting alert information from Ambari'
  s.author      = 'Carmelo Lucio'
  s.email       = 'clucio@gmail.com'
  s.license     = 'MIT'
  s.homepage    = ''
  s.platform               = Gem::Platform::RUBY
  s.post_install_message   = 'You can use the embedded Ruby by setting EMBEDDED_RUBY=true in /etc/default/sensu'
  s.require_paths          = ['lib']
  s.required_ruby_version  = '>= 1.9.3'

  s.executables            = Dir.glob('bin/**/*').map { |file| File.basename(file) }
  s.files                  = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md)

  s.add_runtime_dependency 'json', '~> 1.0', '>= 1.0.0'
  s.add_runtime_dependency 'rest-client', '~> 1.8', '>= 1.8.0'
  s.add_runtime_dependency 'sensu-plugin', '~> 1.2', '>= 1.2.0'

end
