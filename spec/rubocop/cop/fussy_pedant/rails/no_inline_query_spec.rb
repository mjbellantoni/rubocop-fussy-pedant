# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::NoInlineQuery, :config do
  let(:config) do
    RuboCop::Config.new(
      'FussyPedant/Rails/NoInlineQuery' => {
        'Enabled' => true,
        'ForbiddenMethods' => described_class::DEFAULT_FORBIDDEN_METHODS.to_a
      },
      'AllCops' => { 'DisplayCopNames' => true }
    )
  end

  let(:message) do
    'FussyPedant/Rails/NoInlineQuery: Name this query: add a scope to ' \
      'the model or a query object in app/queries. Call sites do not ' \
      'build queries.'
  end

  it 'registers an offense for `where` on a model constant' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.where(status: :pending)
            ^^^^^ #{message}
    RUBY
  end

  it 'registers an offense for a builder on an association' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      user.orders.includes(:line_items)
                  ^^^^^^^^ #{message}
    RUBY
  end

  it 'registers an offense for a receiverless builder' do
    expect_offense(<<~RUBY, 'app/services/report.rb')
      where(status: :pending)
      ^^^^^ #{message}
    RUBY
  end

  it 'registers an offense through safe navigation' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      user&.orders&.joins(:customer)
                    ^^^^^ #{message}
    RUBY
  end

  it 'registers an offense for `pluck`, which names a column' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.pending.pluck(:email)
                    ^^^^^ #{message}
    RUBY
  end

  it 'reports once per chain, at the innermost forbidden call' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.joins(:customer).where(status: :pending).limit(5)
            ^^^^^ #{message}
    RUBY
  end

  it 'reports each of two sibling chains' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      a = Order.where(status: :pending)
                ^^^^^ #{message}
      b = Invoice.where(paid: false)
                  ^^^^^ #{message}
    RUBY
  end

  it 'reports separately across a block in the chain' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.where(status: :pending).map { |o| o.total }.first(3)
            ^^^^^ #{message}
    RUBY
  end

  it 'walks through a numbered-parameter block receiver' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.joins(:customer).map { _1.total }
            ^^^^^ #{message}
    RUBY
  end

  it 'accepts a chain of named scopes' do
    expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.pending.overdue.recent
    RUBY
  end

  it 'accepts consumers that name nothing' do
    expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.pending.first
      Order.pending.count
      Order.pending.each { |order| order.notify }
      Foo.enabled.find(1)
      Order.find_by(reference: reference)
    RUBY
  end

  described_class::DEFAULT_FORBIDDEN_METHODS.each do |method|
    next if described_class::ARGUMENT_REQUIRED.include?(method)

    it "registers an offense for `#{method}`" do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.#{method}(:x)
              #{'^' * method.length} #{message}
      RUBY
    end
  end
end
