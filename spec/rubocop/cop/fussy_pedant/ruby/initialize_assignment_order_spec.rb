# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::InitializeAssignmentOrder, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for out-of-order assignments' do
    expect_offense(<<~RUBY)
      def initialize
        @x = 1
        @bar = 2
        ^^^^^^^^ FussyPedant/Ruby/InitializeAssignmentOrder: Alphabetize instance variable assignments in `initialize`; `@bar` should come before `@x`.
        @foo = 3
      end
    RUBY
  end

  it 'accepts alphabetical assignments' do
    expect_no_offenses(<<~RUBY)
      def initialize
        @bar = 2
        @foo = 3
        @x = 1
      end
    RUBY
  end

  it 'treats non-assignment statements as run boundaries' do
    expect_no_offenses(<<~RUBY)
      def initialize
        @z = 1
        super
        @a = 2
      end
    RUBY
  end

  it 'ignores assignments outside initialize' do
    expect_no_offenses(<<~RUBY)
      def configure
        @z = 1
        @a = 2
      end
    RUBY
  end

  it 'ignores a single assignment' do
    expect_no_offenses(<<~RUBY)
      def initialize
        @z = 1
      end
    RUBY
  end
end
