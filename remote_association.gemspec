# -*- encoding: utf-8 -*-
require File.expand_path('../lib/remote_association/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Denis Yagofarov"]
  gem.email         = ["denyago@gmail.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "remote_association"
  gem.require_paths = ["lib"]
  gem.version       = RemoteAssociation::VERSION

  gem.add_development_dependency 'rspec', '~> 2.11'
end
