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

  describe 'names that collide with non-ActiveRecord receivers' do
    it 'accepts `order` as a noun' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        line_item.order
      RUBY
    end

    it 'registers an offense for `order` with arguments' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.pending.order(created_at: :desc)
                      ^^^^^ #{message}
      RUBY
    end

    it 'accepts Enumerable `select` with a block and no arguments' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        orders.select { |order| order.pending? }
      RUBY
    end

    it 'registers an offense for `select` with a column argument' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.select(:id, :status)
              ^^^^^^ #{message}
      RUBY
    end

    it 'accepts `limit` as a reader' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        plan.limit
      RUBY
    end

    it 'registers an offense for `limit` with arguments' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.pending.limit(5)
                      ^^^^^ #{message}
      RUBY
    end

    it 'accepts `offset` as a reader' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        rect.offset
      RUBY
    end

    it 'registers an offense for `offset` with arguments' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.pending.offset(20)
                      ^^^^^^ #{message}
      RUBY
    end

    it 'accepts `group` as a reader' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        membership.group
      RUBY
    end

    it 'registers an offense for `group` with arguments' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.group(:status)
              ^^^^^ #{message}
      RUBY
    end

    it 'accepts a receiverless reader with no arguments' do
      expect_no_offenses(<<~RUBY, 'app/services/report.rb')
        def total
          limit
        end
      RUBY
    end
  end

  describe 'directory scoping' do
    let(:config) do
      RuboCop::Config.new(
        'FussyPedant/Rails/NoInlineQuery' => {
          'Enabled' => true,
          'ForbiddenMethods' => described_class::DEFAULT_FORBIDDEN_METHODS.to_a,
          'Exclude' => ['**/app/models/**/*', '**/app/queries/**/*', '**/db/**/*']
        },
        'AllCops' => { 'DisplayCopNames' => true }
      )
    end

    let(:query) { "Order.where(status: :pending)\n" }

    it 'accepts a query in a model' do
      expect_no_offenses(query, 'app/models/order.rb')
    end

    it 'accepts a query in a model concern' do
      expect_no_offenses(query, 'app/models/concerns/payable.rb')
    end

    it 'accepts a query in a query object' do
      expect_no_offenses(query, 'app/queries/overdue_orders_query.rb')
    end

    it 'accepts a query in a migration' do
      expect_no_offenses(query, 'db/migrate/20260101000000_backfill.rb')
    end

    it 'accepts a query in an engine model' do
      expect_no_offenses(query, 'engines/billing/app/models/order.rb')
    end

    it 'registers an offense in a controller' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.where(status: :pending)
              ^^^^^ #{message}
      RUBY
    end

    it 'registers an offense in a service' do
      expect_offense(<<~RUBY, 'app/services/order_report.rb')
        Order.where(status: :pending)
              ^^^^^ #{message}
      RUBY
    end

    it 'registers an offense in a spec' do
      expect_offense(<<~RUBY, 'spec/models/order_spec.rb')
        Order.where(status: :pending)
              ^^^^^ #{message}
      RUBY
    end
  end

  it 'keeps DEFAULT_FORBIDDEN_METHODS in sync with config/default.yml' do
    defaults = YAML.load_file('config/default.yml')
    configured = defaults['FussyPedant/Rails/NoInlineQuery']['ForbiddenMethods']

    expect(configured).to eq(described_class::DEFAULT_FORBIDDEN_METHODS.to_a)
  end

  it 'excludes the directories the design names' do
    defaults = YAML.load_file('config/default.yml')
    excluded = defaults['FussyPedant/Rails/NoInlineQuery']['Exclude']

    expect(excluded).to eq(
      ['**/app/models/**/*', '**/app/queries/**/*', '**/db/**/*']
    )
  end
end
