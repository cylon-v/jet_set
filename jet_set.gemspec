# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jet_set/version'

Gem::Specification.new do |spec|
  spec.name          = 'jet_set'
  spec.version       = JetSet::VERSION
  spec.authors       = ['Vladimir Kalinkin']
  spec.email         = ['vova.kalinkin@gmail.com']

  spec.summary       = 'JetSet is a microscopic ORM for DDD projects.'
  spec.description   = ''
  spec.homepage      = 'https://github.com/cylon-v/jet_set'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'hypo', '~> 0.8.3'
  spec.add_dependency 'pg', '~> 1.0.0'
  spec.add_dependency 'sqlite3', '~> 1.3.13'
  spec.add_dependency 'sequel', '~> 5.4.0'


  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
