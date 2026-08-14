# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::SpaceInsidePercentArray, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and corrects a %w array without inner spaces' do
    expect_offense(<<~RUBY)
      %w[foo bar]
      ^^^^^^^^^^^ FussyPedant/Ruby/SpaceInsidePercentArray: Put a space inside the delimiters of a percent array.
    RUBY
    expect_correction(<<~RUBY)
      %w[ foo bar ]
    RUBY
  end

  it 'registers an offense when only the leading space is missing' do
    expect_offense(<<~RUBY)
      %i[foo ]
      ^^^^^^^^ FussyPedant/Ruby/SpaceInsidePercentArray: Put a space inside the delimiters of a percent array.
    RUBY
    expect_correction(<<~RUBY)
      %i[ foo ]
    RUBY
  end

  it 'accepts a correctly spaced array' do
    expect_no_offenses('%w[ foo bar ]')
  end

  it 'accepts an empty percent array' do
    expect_no_offenses('%w[]')
  end

  it 'ignores non-array percent literals' do
    expect_no_offenses('%q(foo)')
  end

  it 'handles other delimiters' do
    expect_offense(<<~RUBY)
      %w(foo)
      ^^^^^^^ FussyPedant/Ruby/SpaceInsidePercentArray: Put a space inside the delimiters of a percent array.
    RUBY
    expect_correction(<<~RUBY)
      %w( foo )
    RUBY
  end

  it 'leaves a multiline %w array untouched' do
    expect_no_offenses(<<~RUBY)
      %w[
        foo
        bar
      ]
    RUBY
  end

  it 'corrects a %W array with interpolation' do
    expect_offense(<<~'RUBY')
      %W[foo#{bar}]
      ^^^^^^^^^^^^^ FussyPedant/Ruby/SpaceInsidePercentArray: Put a space inside the delimiters of a percent array.
    RUBY
    expect_correction(<<~'RUBY')
      %W[ foo#{bar} ]
    RUBY
  end

  it 'corrects a brace-delimited array' do
    expect_offense(<<~RUBY)
      %i{foo}
      ^^^^^^^ FussyPedant/Ruby/SpaceInsidePercentArray: Put a space inside the delimiters of a percent array.
    RUBY
    expect_correction(<<~RUBY)
      %i{ foo }
    RUBY
  end
end
