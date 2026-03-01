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

  context 'when comment is a rubocop directive' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # rubocop:disable Layout/LineLength, Style/FrozenStringLiteralComment, Style/MutableConstant
      RUBY
    end
  end

  context 'when comment is a magic comment' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # frozen_string_literal: true
      RUBY
    end
  end

  context 'when comment is a shebang' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        #!/usr/bin/env ruby -w --some-very-long-flag --another-flag
      RUBY
    end
  end

  context 'when comment is an annotation keyword line' do
    it 'does not register an offense for TODO' do
      expect_no_offenses(<<~RUBY)
        # TODO: This is a very long todo item that exceeds the column limit by a significant margin surely.
      RUBY
    end

    it 'does not register an offense for FIXME' do
      expect_no_offenses(<<~RUBY)
        # FIXME: This is a very long fixme item that exceeds the column limit by a significant margin surely.
      RUBY
    end

    it 'does not register an offense for NOTE' do
      expect_no_offenses(<<~RUBY)
        # NOTE: This is a very long note that exceeds the column limit by a significant margin and should pass.
      RUBY
    end
  end

  context 'when comment is an inline/trailing comment' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        x = 1 # This trailing comment is very long and exceeds forty column limit for sure definitely.
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
