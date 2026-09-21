# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::NoNegatedPredicate, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a negated predicate with an explicit receiver' do
    expect_offense(<<~RUBY)
      !order.complete?
      ^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
    RUBY
  end

  it 'registers an offense for `not` applied to a predicate' do
    expect_offense(<<~RUBY)
      not order.complete?
      ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
    RUBY
  end

  it 'registers an offense for a negated predicate on implicit self' do
    expect_offense(<<~RUBY)
      !complete?
      ^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
    RUBY
  end

  it 'registers an offense for a negated predicate on explicit self' do
    expect_offense(<<~RUBY)
      !self.complete?
      ^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
    RUBY
  end

  it 'registers an offense for a negated predicate reached by safe navigation' do
    expect_offense(<<~RUBY)
      !order&.complete?
      ^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
    RUBY
  end

  it 'registers an offense when the negation is nested in a larger expression' do
    expect_offense(<<~RUBY)
      if !order.complete? && order.paid?
         ^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
        ship(order)
      end
    RUBY
  end

  it 'registers a single offense for a double negation' do
    expect_offense(<<~RUBY)
      !!order.complete?
       ^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `complete?`.
    RUBY
  end

  it 'accepts negation of a non-predicate method' do
    expect_no_offenses('!order.complete')
  end

  it 'accepts negation of a local variable' do
    expect_no_offenses(<<~RUBY)
      complete = true
      !complete
    RUBY
  end

  it 'accepts a negated predicate that takes a positional argument' do
    expect_no_offenses('!user.authorized_for?(:admin)')
  end

  it 'accepts a negated predicate that takes a block' do
    expect_no_offenses('!order.matches? { |line| line.taxable? }')
  end

  described_class::DEFAULT_ALLOWED_METHODS.each do |predicate|
    it "accepts negated `#{predicate}`" do
      expect_no_offenses("!order.#{predicate}")
    end
  end

  %w[empty? any? none? positive? negative? even? odd? zero?
     blank? present? persisted? new_record?].each do |predicate|
    it "registers an offense for negated `#{predicate}`, which has an inverse" do
      expect_offense(<<~RUBY, predicate: predicate)
        !order.%{predicate}
        ^^^^^^^^{predicate} FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `#{predicate}`.
      RUBY
    end
  end

  it 'registers an offense for a predicate that is not allowed by default' do
    expect_offense(<<~RUBY)
      !record.valid?
      ^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `valid?`.
    RUBY
  end

  context 'with AllowedMethods configured' do
    let(:config) do
      RuboCop::Config.new(
        'AllCops' => { 'DisplayCopNames' => true },
        'FussyPedant/Ruby/NoNegatedPredicate' => { 'AllowedMethods' => ['complete?'] }
      )
    end

    it 'accepts a predicate named in the list' do
      expect_no_offenses('!order.complete?')
    end

    it 'replaces rather than extends the default list' do
      expect_offense(<<~RUBY)
        !x.nil?
        ^^^^^^^ FussyPedant/Ruby/NoNegatedPredicate: Define an inverse predicate instead of negating `nil?`.
      RUBY
    end
  end

  it 'keeps DEFAULT_ALLOWED_METHODS in sync with config/default.yml' do
    defaults = YAML.load_file('config/default.yml')
    configured = defaults.dig('FussyPedant/Ruby/NoNegatedPredicate', 'AllowedMethods')

    expect(configured).to eq(described_class::DEFAULT_ALLOWED_METHODS.to_a)
  end
end
