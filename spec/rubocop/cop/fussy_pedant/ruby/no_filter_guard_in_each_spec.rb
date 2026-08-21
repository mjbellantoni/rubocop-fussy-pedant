# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::NoFilterGuardInEach, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a next unless filter guard' do
    expect_offense(<<~RUBY)
      RECIPIENT_FIELDS.each do |field|
        next unless permitted.key?(field)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `select` on the receiver instead of a `next unless` filter guard.
        permitted[field] = Array(permitted[field]).join(", ")
      end
    RUBY
  end

  it 'registers an offense for a next if filter guard' do
    expect_offense(<<~RUBY)
      RECIPIENT_FIELDS.each do |field|
        next if permitted.key?(field)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `reject` on the receiver instead of a `next if` filter guard.
        permitted[field] = nil
      end
    RUBY
  end

  it 'does not flag a condition that ignores the block parameter' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next unless enabled?
        process(field)
      end
    RUBY
  end

  it 'does not flag a condition containing an assignment' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next unless (value = lookup(field))
        process(value)
      end
    RUBY
  end

  it 'does not flag a condition calling a bang method' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next unless field.strip!
        process(field)
      end
    RUBY
  end

  it 'does not flag a guard that is not the first statement' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        log(field)
        next unless field.ok?
        process(field)
      end
    RUBY
  end

  it 'does not flag consecutive guards' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next unless field.ok?
        next if field.empty?
        process(field)
      end
    RUBY
  end

  it 'does not flag next with a value' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next 1 unless field.ok?
        process(field)
      end
    RUBY
  end

  it 'does not flag a non-modifier if wrapping next' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        if field.ok?
          next
        end
        process(field)
      end
    RUBY
  end

  it 'does not flag a guard in map' do
    expect_no_offenses(<<~RUBY)
      fields.map do |field|
        next unless field.ok?
        field.to_s
      end
    RUBY
  end

  it 'does not flag a guard with no following statement' do
    expect_no_offenses(<<~RUBY)
      fields.each { |field| next unless field.ok? }
    RUBY
  end

  it 'does not flag a numbered block parameter' do
    expect_no_offenses(<<~RUBY)
      fields.each do
        next unless _1.ok?
        process(_1)
      end
    RUBY
  end
end
