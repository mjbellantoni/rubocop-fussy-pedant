# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::AttrOrder, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for two accessors out of alphabetical order' do
    expect_offense(<<~RUBY)
      class Form
        attr_accessor :retained_attachment_ids
        attr_accessor :existing_attachment_parts
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:existing_attachment_parts` to come before `:retained_attachment_ids` (alphabetical order).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Form
        attr_accessor :existing_attachment_parts
        attr_accessor :retained_attachment_ids
      end
    RUBY
  end

  it 'does not register an offense when a blank line separates the accessors' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_accessor :retained_attachment_ids

        attr_accessor :existing_attachment_parts
      end
    RUBY
  end

  it 'does not correct a run whose declaration carries a trailing comment' do
    expect_offense(<<~RUBY)
      class Form
        attr_accessor :retained_attachment_ids # legacy
        attr_accessor :existing_attachment_parts
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:existing_attachment_parts` to come before `:retained_attachment_ids` (alphabetical order).
      end
    RUBY

    expect_no_corrections
  end

  it 'registers an offense for visibility-wrapped accessors out of order' do
    expect_offense(<<~RUBY)
      class Form
        private attr_reader :beta
        private attr_reader :alpha
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:alpha` to come before `:beta` (alphabetical order).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Form
        private attr_reader :alpha
        private attr_reader :beta
      end
    RUBY
  end

  it 'sorts a run of three in a single correction' do
    expect_offense(<<~RUBY)
      class Form
        attr_reader :charlie
        attr_reader :bravo
        ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:bravo` to come before `:charlie` (alphabetical order).
        attr_reader :alpha
        ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:alpha` to come before `:bravo` (alphabetical order).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Form
        attr_reader :alpha
        attr_reader :bravo
        attr_reader :charlie
      end
    RUBY
  end

  it 'does not register an offense for accessors already in order' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_accessor :existing_attachment_parts
        attr_accessor :retained_attachment_ids
      end
    RUBY
  end

  it 'does not order one macro against another' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_reader :zulu
        attr_accessor :alpha
        attr_writer :beta
      end
    RUBY
  end

  it 'does not order a public accessor against a private one' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_reader :zulu
        private attr_reader :alpha
      end
    RUBY
  end

  it 'ends the run at a comment line' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_reader :zulu
        # Identifiers.
        attr_reader :alpha
      end
    RUBY
  end

  it 'ends the run at a multi-attribute declaration' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_reader :zulu
        attr_reader :mike, :november
        attr_reader :alpha
      end
    RUBY
  end

  it 'ends the run at unrelated code' do
    expect_no_offenses(<<~RUBY)
      class Form
        attr_reader :zulu
        include Comparable
        attr_reader :alpha
      end
    RUBY
  end

  it 'registers an offense after a bare private keyword' do
    expect_offense(<<~RUBY)
      class Form
        private

        attr_reader :beta
        attr_reader :alpha
        ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:alpha` to come before `:beta` (alphabetical order).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Form
        private

        attr_reader :alpha
        attr_reader :beta
      end
    RUBY
  end

  it 'registers an offense inside a module body' do
    expect_offense(<<~RUBY)
      module Attachable
        attr_reader :beta
        attr_reader :alpha
        ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:alpha` to come before `:beta` (alphabetical order).
      end
    RUBY

    expect_correction(<<~RUBY)
      module Attachable
        attr_reader :alpha
        attr_reader :beta
      end
    RUBY
  end

  it 'orders string arguments alongside symbols' do
    expect_offense(<<~RUBY)
      class Form
        attr_reader 'beta'
        attr_reader :alpha
        ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/AttrOrder: Expected `:alpha` to come before `:beta` (alphabetical order).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Form
        attr_reader :alpha
        attr_reader 'beta'
      end
    RUBY
  end
end
