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

  it 'registers one offense for stacked unless guards' do
    expect_offense(<<~RUBY)
      fields.each do |field|
        next unless field.ok?
        ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `select` on the receiver instead of these `next` filter guards.
        next unless field.ready?
        process(field)
      end
    RUBY
  end

  it 'registers one offense for stacked if guards' do
    expect_offense(<<~RUBY)
      fields.each do |field|
        next if field.blank?
        ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `reject` on the receiver instead of these `next` filter guards.
        next if field.stale?
        process(field)
      end
    RUBY
  end

  it 'registers one offense for stacked mixed guards' do
    expect_offense(<<~RUBY)
      fields.each do |field|
        next unless field.ok?
        ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `select`/`reject` on the receiver instead of these `next` filter guards.
        next if field.empty?
        process(field)
      end
    RUBY
  end

  it 'registers an offense for a numbered block parameter' do
    expect_offense(<<~RUBY)
      fields.each do
        next unless _1.ok?
        ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `select` on the receiver instead of a `next unless` filter guard.
        process(_1)
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

  it 'does not flag a numbered block condition that ignores the parameter' do
    expect_no_offenses(<<~RUBY)
      fields.each do
        next unless enabled?
        process(_1)
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

  it 'does not flag a pure guard followed by a guard with a side effect' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next unless field.ok?
        next unless field.strip!
        process(field)
      end
    RUBY
  end

  it 'does not flag when every statement is a guard' do
    expect_no_offenses(<<~RUBY)
      fields.each do |field|
        next unless field.ok?
        next if field.empty?
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

  context 'with Ruby 3.4' do
    let(:ruby_version) { 3.4 }

    it 'registers an offense for an it block parameter' do
      expect_offense(<<~RUBY)
        fields.each do
          next unless it.ok?
          ^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoFilterGuardInEach: Use `select` on the receiver instead of a `next unless` filter guard.
          process(it)
        end
      RUBY
    end
  end
end
