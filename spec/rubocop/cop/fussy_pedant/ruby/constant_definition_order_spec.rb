# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::ConstantDefinitionOrder, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for out-of-order constants' do
    expect_offense(<<~RUBY)
      class Foo
        XYLOPHONE = 1
        DINGUS = "foo"
        ^^^^^^^^^^^^^^ FussyPedant/Ruby/ConstantDefinitionOrder: Alphabetize constant definitions; `DINGUS` should come before `XYLOPHONE`.
      end
    RUBY
  end

  it 'accepts alphabetical constants' do
    expect_no_offenses(<<~RUBY)
      class Foo
        DINGUS = "foo"
        XYLOPHONE = 1
      end
    RUBY
  end

  it 'treats non-constant statements as run boundaries' do
    expect_no_offenses(<<~RUBY)
      class Foo
        Z = 1
        attr_reader :a
        A = 2
      end
    RUBY
  end

  it 'works inside modules' do
    expect_offense(<<~RUBY)
      module Foo
        B = 1
        A = 2
        ^^^^^ FussyPedant/Ruby/ConstantDefinitionOrder: Alphabetize constant definitions; `A` should come before `B`.
      end
    RUBY
  end

  it 'ignores a single constant' do
    expect_no_offenses(<<~RUBY)
      class Foo
        A = 1
      end
    RUBY
  end

  it 'does not merge constants from a nested class into the outer run' do
    expect_no_offenses(<<~RUBY)
      class Foo
        Z = 1

        class Bar
          A = 2
        end
      end
    RUBY
  end

  it 'accepts a constant that depends on the one before it' do
    expect_no_offenses(<<~RUBY)
      class Foo
        UNDO_WINDOW = 30
        SEND_DELAY = UNDO_WINDOW + 1
      end
    RUBY
  end

  it 'orders constants that follow a dependency' do
    expect_offense(<<~RUBY)
      class Foo
        UNDO_WINDOW = 30
        SEND_DELAY = UNDO_WINDOW + 1
        APPLE = 2
        ^^^^^^^^^ FussyPedant/Ruby/ConstantDefinitionOrder: Alphabetize constant definitions; `APPLE` should come before `SEND_DELAY`.
      end
    RUBY
  end

  it 'orders constants that precede a dependency' do
    expect_offense(<<~RUBY)
      class Foo
        ZEBRA = 1
        APPLE = 2
        ^^^^^^^^^ FussyPedant/Ruby/ConstantDefinitionOrder: Alphabetize constant definitions; `APPLE` should come before `ZEBRA`.
        SEND_DELAY = APPLE + 1
      end
    RUBY
  end

  it 'keeps ordering when the constant read is defined elsewhere' do
    expect_offense(<<~RUBY)
      class Foo
        ZEBRA = 1
        APPLE = OUTSIDE + 1
        ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/ConstantDefinitionOrder: Alphabetize constant definitions; `APPLE` should come before `ZEBRA`.
      end
    RUBY
  end

  it 'finds a dependency nested inside the value' do
    expect_no_offenses(<<~RUBY)
      class Foo
        LIMIT = 5
        BOUNDS = [0, LIMIT].freeze
      end
    RUBY
  end
end
