# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gistto'

Gem::Specification.new do |gem|
  gem.name          = "gistto"
  gem.version       = Gistto::VERSION
  gem.license       = "MIT"
  gem.authors       = ["erikwco"]
  gem.email         = ["erikchacon@me.com"]
  gem.description   = %q{Gist Client with multiples and suitables functionalities}
  gem.summary       = %q{Gist Client for GitHub}
  gem.homepage      = "https://github.com/erikwco/gistto"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
