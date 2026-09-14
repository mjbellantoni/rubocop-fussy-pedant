# frozen_string_literal: true

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
end
