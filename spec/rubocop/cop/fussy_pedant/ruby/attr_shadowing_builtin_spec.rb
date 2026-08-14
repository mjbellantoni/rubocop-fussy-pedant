# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::AttrShadowingBuiltin, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for attr_reader shadowing a builtin' do
    expect_offense(<<~RUBY)
      attr_reader :method
                  ^^^^^^^ FussyPedant/Ruby/AttrShadowingBuiltin: `method` shadows a built-in method; choose a non-colliding name.
    RUBY
  end

  it 'registers an offense for attr_accessor shadowing a builtin' do
    expect_offense(<<~RUBY)
      attr_accessor :class, :name
                    ^^^^^^ FussyPedant/Ruby/AttrShadowingBuiltin: `class` shadows a built-in method; choose a non-colliding name.
    RUBY
  end

  it 'accepts non-colliding names' do
    expect_no_offenses('attr_reader :http_method, :name')
  end

  it 'ignores attr_writer (only defines name=)' do
    expect_no_offenses('attr_writer :method')
  end

  context 'with AllowedNames' do
    let(:config) do
      RuboCop::Config.new(
        'FussyPedant/Ruby/AttrShadowingBuiltin' => { 'AllowedNames' => ['display'] }
      )
    end

    it 'removes the allowed name from the disallowed set' do
      expect_no_offenses('attr_reader :display')
    end
  end
end
