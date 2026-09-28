# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::MemoizationBody, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a multi-statement memoization with a rescue' do
    expect_offense(<<~RUBY)
      def structured_content
        @structured_content ||= begin
                                ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@structured_content` memoization into a named method.
          parsed = message.parsed
          parsed.is_a?(Hash) ? parsed : {}
        rescue JSON::ParserError
          {}
        end
      end
    RUBY
  end

  it 'registers an offense for a multi-statement memoization without a rescue' do
    expect_offense(<<~RUBY)
      def totals
        @totals ||= begin
                    ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@totals` memoization into a named method.
          rows = load_rows
          rows.sum(&:amount)
        end
      end
    RUBY
  end

  it 'registers an offense for a single-statement memoization with a rescue' do
    expect_offense(<<~RUBY)
      def payload
        @payload ||= begin
                     ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@payload` memoization into a named method.
          message.parsed
        rescue JSON::ParserError
          {}
        end
      end
    RUBY
  end

  it 'registers an offense for a single-statement memoization with an ensure' do
    expect_offense(<<~RUBY)
      def report
        @report ||= begin
                    ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@report` memoization into a named method.
          build_report
        ensure
          cleanup
        end
      end
    RUBY
  end

  it 'registers an offense for a memoization with a rescue/else' do
    expect_offense(<<~RUBY)
      def settings
        @settings ||= begin
                      ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@settings` memoization into a named method.
          raw = read_settings
        rescue Errno::ENOENT
          {}
        else
          parse(raw)
        end
      end
    RUBY
  end

  it 'registers an offense for a memoization buried inside a longer method' do
    expect_offense(<<~RUBY)
      def render
        log(:start)
        @body ||= begin
                  ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@body` memoization into a named method.
          template = lookup_template
          template.render(self)
        end
      end
    RUBY
  end

  # Pins the offence to the `begin` keyword rather than the whole
  # block. Only a single-line `begin` can tell the two apart: where
  # `begin` ends its line, both ranges cover the same first-line
  # columns and every multi-line example above is blind to the
  # difference. `rubocop --format json` is not: 5 columns against 38.
  it 'highlights the begin keyword, not the whole block' do
    expect_offense(<<~RUBY)
      def totals
        @totals ||= begin; rows = load_rows; rows.sum(&:amount); end
                    ^^^^^ FussyPedant/Ruby/MemoizationBody: Extract the body of the `@totals` memoization into a named method.
      end
    RUBY
  end

  # Core Style/RedundantBegin already flags this, and its advice --
  # delete the `begin` -- beats extracting a method.
  it 'accepts a single-statement memoization with no rescue' do
    expect_no_offenses(<<~RUBY)
      def totals
        @totals ||= begin
          rows.sum(&:amount)
        end
      end
    RUBY
  end

  it 'accepts an empty begin block' do
    expect_no_offenses(<<~RUBY)
      def totals
        @totals ||= begin
        end
      end
    RUBY
  end

  it 'accepts a memoization whose body is already a named method' do
    expect_no_offenses(<<~RUBY)
      def structured_content
        @structured_content ||= compute_structured_content
      end
    RUBY
  end

  # The next two record a scope boundary rather than guard one. A
  # plain assignment parses to `ivasgn`/`lvasgn` and never reaches
  # `on_or_asgn`, the cop's only callback, so no mutation of this cop
  # can make either example fail. They are documentation, and are not
  # counted as mutation coverage. They would fail if someone widened
  # the cop with an `on_ivasgn` hook, which is the point of keeping
  # them. See doc reference_vacuous_guard_tests.
  it 'accepts a plain instance variable assignment of a begin block' do
    expect_no_offenses(<<~RUBY)
      def initialize(raw)
        @config = begin
          YAML.safe_load(raw)
        rescue Psych::SyntaxError
          {}
        end
      end
    RUBY
  end

  it 'accepts a local variable assigned a begin block' do
    expect_no_offenses(<<~RUBY)
      def process
        parsed = begin
          JSON.parse(raw)
        rescue JSON::ParserError
          nil
        end
        transform(parsed)
      end
    RUBY
  end

  it 'accepts a memoized local variable' do
    expect_no_offenses(<<~RUBY)
      def totals(rows)
        rows ||= begin
          fetched = fetch_rows
          fetched.compact
        end
        rows
      end
    RUBY
  end

  it 'accepts a memoized class variable' do
    expect_no_offenses(<<~RUBY)
      def cache
        @@cache ||= begin
          store = build_store
          store.warm
        end
      end
    RUBY
  end

  it 'accepts a memoized global variable' do
    expect_no_offenses(<<~RUBY)
      def logger
        $logger ||= begin
          io = File.open('log.txt', 'a')
          Logger.new(io)
        end
      end
    RUBY
  end
end
