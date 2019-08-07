Gem::Specification.new do |s|
  s.name          = 'logstash-output-elastic_ent_search'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'Elastic Enterprise Search'
  s.description   = 'Elastic Enterprise Search'
  s.homepage      = 'http://www.elastic.co'
  s.authors       = ['William Wong']
  s.email         = 'william@elastic.co'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_runtime_dependency 'swiftype-enterprise', '~> 3.0', '>= 3.0.0'
  s.add_development_dependency "logstash-devutils"
end
