# frozen_string_literal: true

require 'tempfile'

RSpec.describe RuboCop::FussyPedant::Plugin do
  let(:gemspec) do
    Gem::Specification.load(
      File.expand_path('../../../rubocop-fussy-pedant.gemspec', __dir__)
    )
  end

  # Without this metadata `plugins: rubocop-fussy-pedant` cannot
  # resolve the plugin class, and config/default.yml is never
  # merged, so every Include and cop option in it is ignored.
  it 'names the plugin class in gemspec metadata' do
    expect(gemspec.metadata['default_lint_roller_plugin'])
      .to eq(described_class.name)
  end

  it 'supplies a config file that exists' do
    rules = described_class.new({}).rules(nil)

    expect(rules.value).to exist
  end

  # A consumer whose .rubocop.yml still names the old cop should be told
  # what to rename it to, not handed an unrecognised-cop failure.
  it 'maps the old cop name to the new one' do
    config_file = Tempfile.new(['rubocop', '.yml'])
    config_file.write(<<~YAML)
      FussyPedant/Ruby/NoTerminalGuardClause:
        Enabled: false
    YAML
    config_file.close

    expect { RuboCop::ConfigLoader.load_file(config_file.path) }
      .to raise_error(
        RuboCop::ValidationError,
        %r{renamed to `FussyPedant/Ruby/GuardClausePlacement`}
      )
  ensure
    config_file&.unlink
  end
end
