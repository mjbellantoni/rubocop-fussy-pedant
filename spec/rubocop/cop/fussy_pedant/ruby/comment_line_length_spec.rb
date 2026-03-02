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

  context 'when multiple consecutive comment lines exceed the limit' do
    it 'registers one offense per paragraph' do
      expect_offense(<<~RUBY)
        # This is the first very long line in a paragraph that exceeds the column limit.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [80/40]
        # This is the second long line in that same paragraph and also exceeds the limit.
      RUBY
    end
  end

  context 'when paragraphs are separated by blank lines' do
    it 'registers separate offenses for each paragraph' do
      expect_offense(<<~RUBY)
        # This is a long line in paragraph one that goes beyond the limit for sure yes.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [79/40]

        # This is a long line in paragraph two that also goes beyond the column limit.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [78/40]
      RUBY
    end
  end

  context 'when paragraphs are separated by empty comment lines' do
    it 'registers separate offenses for each paragraph' do
      expect_offense(<<~RUBY)
        # This is a long line in paragraph one that goes beyond the limit for sure yes.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [79/40]
        #
        # This is a long line in paragraph two that also goes beyond the column limit.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [78/40]
      RUBY
    end
  end

  context 'when a paragraph has no overlength lines' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        # Short line one.
        # Short line two.
      RUBY
    end
  end

  context 'with URLs' do
    context 'when a line contains only a URL' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # https://example.com/very/long/path/that/exceeds/the/column/limit/by/a/lot
        RUBY
      end
    end

    context 'when a comment is just a URL with no other text' do
      it 'does not register an offense even if URL exceeds limit' do
        expect_no_offenses(<<~RUBY)
          # https://example.com/very/long/path/that/exceeds/limit
        RUBY
      end
    end

    context 'when a URL is mid-sentence' do
      it 'wraps around the URL keeping it intact' do
        expect_offense(<<~RUBY)
          # See the docs at https://example.com/long/path for more details about this.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [76/40]
        RUBY

        expect_correction(<<~RUBY)
          # See the docs at
          # https://example.com/long/path for more
          # details about this.
        RUBY
      end
    end

    context 'when a URL exceeds the limit on its own' do
      it 'places the URL on its own line' do
        expect_offense(<<~RUBY)
          # See https://example.com/very/long/path/that/exceeds/the/column/limit for details.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [83/40]
        RUBY

        expect_correction(<<~RUBY)
          # See
          # https://example.com/very/long/path/that/exceeds/the/column/limit
          # for details.
        RUBY
      end
    end
  end

  context 'with edge cases' do
    context 'when a single word exceeds the limit' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # Pneumonoultramicroscopicsilicovolcanoconiosis
        RUBY
      end
    end

    context 'when comment has no space after #' do
      it 'still detects and corrects' do
        expect_offense(<<~RUBY)
          #This comment has no space and is way too long to fit within the limit.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [71/40]
        RUBY

        expect_correction(<<~RUBY)
          # This comment has no space and is way
          # too long to fit within the limit.
        RUBY
      end
    end

    context 'with different indentation levels breaking paragraphs' do
      it 'treats them as separate paragraphs' do
        expect_offense(<<~RUBY)
          # This is a long outer comment that exceeds the column limit by a lot.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [70/40]
          def foo
            # This indented comment is also too long and exceeds the limit here.
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [70/40]
          end
        RUBY
      end
    end

    context 'when a YARD tag line exceeds the limit' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @param name [String] the full name of the user to be displayed in the profile
        RUBY
      end
    end

    context 'when indented example code exceeds the limit' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          # @example Collection usage
          #   <%= render Inbox::CommunicationItemComponent.with_collection(@communications) %>
        RUBY
      end
    end

    context 'when a YARD example tag is adjacent to prose' do
      it 'does not merge them' do
        expect_offense(<<~RUBY)
          # This is a very long description that definitely exceeds the limit.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [68/40]
          # @example Collection usage
          #   <%= render Foo.bar %>
        RUBY

        expect_correction(<<~RUBY)
          # This is a very long description that
          # definitely exceeds the limit.
          # @example Collection usage
          #   <%= render Foo.bar %>
        RUBY
      end
    end

    context 'when the file has no comments' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          x = 1
          y = 2
        RUBY
      end
    end
  end

  context 'with autocorrect' do
    context 'when a single long comment line needs wrapping' do
      it 'wraps at the column limit' do
        expect_offense(<<~RUBY)
          # This comment is way too long and exceeds the limit badly.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [59/40]
        RUBY

        expect_correction(<<~RUBY)
          # This comment is way too long and
          # exceeds the limit badly.
        RUBY
      end
    end

    context 'when an indented comment needs wrapping' do
      it 'preserves indentation on wrapped lines' do
        expect_offense(<<~RUBY)
          def foo
            # This indented comment is way too long and exceeds the column limit.
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [71/40]
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            # This indented comment is way too
            # long and exceeds the column limit.
          end
        RUBY
      end
    end

    context 'when a multi-line paragraph needs rewrapping' do
      it 'rewraps the entire paragraph' do
        expect_offense(<<~RUBY)
          # This is the first line of a paragraph that is definitely way too long.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [72/40]
          # Second line is also pretty long and exceeds the limit too.
        RUBY

        expect_correction(<<~RUBY)
          # This is the first line of a paragraph
          # that is definitely way too long.
          # Second line is also pretty long and
          # exceeds the limit too.
        RUBY
      end
    end

    context 'when a long line is followed by list items' do
      it 'does not merge list items into the wrapped paragraph' do
        expect_offense(<<~RUBY)
          # Renders a collapsible AI insights section in the thread context sidebar.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [74/40]
          # Features:
          # - AI chat interface
          # - Sparkles icon
          # - Collapsible accordion section
        RUBY

        expect_correction(<<~RUBY)
          # Renders a collapsible AI insights
          # section in the thread context sidebar.
          # Features:
          # - AI chat interface
          # - Sparkles icon
          # - Collapsible accordion section
        RUBY
      end
    end

    context 'when list items themselves are too long' do
      it 'wraps only the offending list item' do
        expect_offense(<<~RUBY)
          # - This list item is way too long and exceeds the column limit badly.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [70/40]
          # - Short item
        RUBY

        expect_correction(<<~RUBY)
          # - This list item is way too long and
          # exceeds the column limit badly.
          # - Short item
        RUBY
      end
    end

    context 'when a header line ending with colon is followed by content' do
      it 'does not merge the following line into the header' do
        expect_offense(<<~RUBY)
          # This is a very long description that definitely exceeds the limit.
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Comment line exceeds 40 columns. [68/40]
          # Options:
          # Set flag to true
        RUBY

        expect_correction(<<~RUBY)
          # This is a very long description that
          # definitely exceeds the limit.
          # Options:
          # Set flag to true
        RUBY
      end
    end
  end
end
