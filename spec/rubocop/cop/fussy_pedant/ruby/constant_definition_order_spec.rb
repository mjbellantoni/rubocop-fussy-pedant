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
end
