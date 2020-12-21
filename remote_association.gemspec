# -*- encoding: utf-8 -*-
require File.expand_path('../lib/remote_association/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Denis Yagofarov"]
  gem.email         = ["denyago@gmail.com"]
  gem.description   = %q{Your model has_one_remote ActiveResource instance}
  gem.summary       = %q{Adds relations to ActiveResource models}
  gem.homepage      = "https://github.com/denyago/remote_association"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(spec)/})
  gem.name          = "remote_association"
  gem.require_paths = ["lib"]
  gem.version       = RemoteAssociation::VERSION

  rails_version = ">= 3.2"

  gem.add_dependency  'activesupport',  rails_version
  gem.add_dependency  'activerecord',   rails_version
  gem.add_dependency  'activeresource', rails_version

  gem.add_development_dependency 'rspec',             '~> 2.11'
  gem.add_development_dependency 'pg',                '~> 0.14'
  gem.add_development_dependency 'database_cleaner',  '~> 0.8'
  gem.add_development_dependency 'fakeweb'
end
