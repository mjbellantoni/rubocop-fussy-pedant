# frozen_string_literal: true

require_relative 'lib/rubocop/fussy_pedant/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-fussy-pedant'
  spec.version = RuboCop::FussyPedant::VERSION
  spec.authors = ['Matthew Bellantoni']
  spec.summary = 'Custom RuboCop cops for Ruby, Rails, and RSpec'

  spec.required_ruby_version = '>= 3.3'

  spec.files = Dir['config/**/*', 'lib/**/*']

  spec.require_paths = ['lib']

  spec.add_dependency 'lint_roller', '~> 1.1'
  spec.add_dependency 'rubocop', '~> 1.0'
  spec.add_dependency 'rubocop-ast', '~> 1.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
