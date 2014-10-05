# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gratan/version'

Gem::Specification.new do |spec|
  spec.name          = 'gratan'
  spec.version       = Gratan::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sgwr_dts@yahoo.co.jp']
  spec.summary       = %q{Gratan is a tool to manage MySQL permissions using Ruby DSL.}
  spec.description   = %q{Gratan is a tool to manage MySQL permissions using Ruby DSL.}
  spec.homepage      = 'https://github.com/winebarrel/gratan'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'mysql2'
  spec.add_dependency "term-ansicolor"
  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'coveralls'
end
