# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::CommentLineLength, :config do
  let(:config) do
    RuboCop::Config.new(
      'FussyPedant/Ruby/CommentLineLength' => { 'Enabled' => true, 'MaxColumn' => 40 }
    )
  end

  context 'when a comment fits within the limit' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # This comment fits just fine.
      RUBY
    end
  end

  context 'when a comment exceeds the limit' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        # This comment is way too long and exceeds the limit badly.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [59/40]
      RUBY
    end
  end

  context 'when an indented comment exceeds the limit' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def foo
          # This indented comment is way too long and exceeds the column limit.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [71/40]
        end
      RUBY
    end
  end

  context 'when a comment is exactly at the limit' do
    it 'does not register an offense' do
      # "# " = 2 chars + 38 chars of text = 40 total
      expect_no_offenses(<<~RUBY)
        # aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
      RUBY
    end
  end
end
