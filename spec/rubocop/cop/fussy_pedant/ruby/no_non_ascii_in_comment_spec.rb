# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::NoNonAsciiInComment, :config do
  let(:config) do
    RuboCop::Config.new(
      'FussyPedant/Ruby/NoNonAsciiInComment' => { 'Enabled' => true }
    )
  end

  context 'when a comment contains an em-dash' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # This is a comment \u2014 with an em-dash.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid non-ASCII characters in comments; use plain ASCII equivalents instead.
      RUBY
    end
  end

  context 'when a comment contains an en-dash' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # Pages 10\u201320 of the document.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid non-ASCII characters in comments; use plain ASCII equivalents instead.
      RUBY
    end
  end

  context 'when a comment contains smart quotes' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # The \u201Cfoo\u201D method is deprecated.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid non-ASCII characters in comments; use plain ASCII equivalents instead.
      RUBY
    end
  end

  context 'when a comment contains an ellipsis' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # Loading\u2026 please wait.
        ^^^^^^^^^^^^^^^^^^^^^^^ Avoid non-ASCII characters in comments; use plain ASCII equivalents instead.
      RUBY
    end
  end

  context 'when a comment uses only plain ASCII' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # This is a normal comment - with a hyphen.
      RUBY
    end
  end

  context 'when a comment has no dashes at all' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # Just a plain comment with no special characters.
      RUBY
    end
  end

  context 'when a trailing comment contains non-ASCII' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        x = 1 # value \u2014 important
              ^^^^^^^^^^^^^^^^^^^ Avoid non-ASCII characters in comments; use plain ASCII equivalents instead.
      RUBY
    end
  end

  context 'when code contains non-ASCII but comment does not' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        x = "\u2014 em dash in string"
        # Normal comment here.
      RUBY
    end
  end
end
