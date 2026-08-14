# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::ConsistentArrayCoercion, :config do
  let(:supported_styles) { %w[array_coercion logical_or] }
  let(:cop_config) { { 'EnforcedStyle' => 'array_coercion' } }
  let(:config) do
    RuboCop::Config.new(
      'AllCops' => { 'DisplayCopNames' => true },
      'FussyPedant/Ruby/ConsistentArrayCoercion' =>
        cop_config.merge('SupportedStyles' => supported_styles)
    )
  end

  context 'with default style (array_coercion)' do
    it 'registers an offense for (x || [])' do
      expect_offense(<<~RUBY)
        (rows || [])
        ^^^^^^^^^^^^ FussyPedant/Ruby/ConsistentArrayCoercion: Use `Array(...)` to ensure an array, not `(... || [])`.
      RUBY
    end

    it 'accepts Array(x)' do
      expect_no_offenses('Array(rows)')
    end

    it 'ignores || with a non-empty-array default' do
      expect_no_offenses('(rows || other)')
    end

    it 'ignores || with a non-array default' do
      expect_no_offenses('(rows || {})')
    end
  end

  context 'with logical_or style' do
    let(:cop_config) { { 'EnforcedStyle' => 'logical_or' } }

    it 'registers an offense for Array(x)' do
      expect_offense(<<~RUBY)
        Array(rows)
        ^^^^^^^^^^^ FussyPedant/Ruby/ConsistentArrayCoercion: Use `(... || [])` to ensure an array, not `Array(...)`.
      RUBY
    end

    it 'accepts (x || [])' do
      expect_no_offenses('(rows || [])')
    end
  end
end
