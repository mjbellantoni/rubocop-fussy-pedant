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

  it 'registers an offense for a builder that takes no arguments' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.pending.distinct
                    ^^^^^^^^ #{message}
    RUBY
  end

  it 'reports once per chain, at the innermost forbidden call' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.joins(:customer).where(status: :pending).limit(5)
            ^^^^^ #{message}
    RUBY
  end

  it 'reports once when a named scope sits between two forbidden calls' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.where(active: true).pending.limit(5)
            ^^^^^ #{message}
    RUBY
  end

  it 'reports once for a safe-navigation chain of forbidden calls' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      user&.orders&.where(status: :pending)&.limit(5)
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

  it 'reports once across a block receiver in the chain' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.where(status: :pending).map { |o| o.total }.select(:id)
            ^^^^^ #{message}
    RUBY
  end

  it 'reports once across a numbered-parameter block receiver' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.where(status: :pending).map { _1.total }.select(:id)
            ^^^^^ #{message}
    RUBY
  end

  context 'with Ruby 3.4' do
    let(:ruby_version) { 3.4 }

    it 'reports once across an `it` block receiver' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.where(status: :pending).map { it.total }.select(:id)
              ^^^^^ #{message}
      RUBY
    end
  end

  it 'reports a query built inside a block separately' do
    expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.where(active: true).map do |o|
            ^^^^^ #{message}
        o.items.where(paid: true)
                ^^^^^ #{message}
      end
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

  it 'accepts the methods deliberately left off the list' do
    expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
      Order.pluck(:email)
      Order.pending.pick(:id)
      collection.ids
      policy_scope.none
      list.reorder(params[:ids])
      validator.not(rule)
      Order.excluding(current_user)
      records.excluding(current_user)
    RUBY
  end

  # ActiveRecord's form of most builders takes arguments, but a handful
  # are idiomatically called bare. Exercising those with `(:x)` would
  # never catch a regression that made arguments mandatory everywhere.
  argless_builders = %w[distinct reverse_order unscoped strict_loading].freeze

  described_class::DEFAULT_FORBIDDEN_METHODS.each do |method|
    next if described_class::ARGUMENT_REQUIRED.include?(method)
    next if argless_builders.include?(method)

    it "registers an offense for `#{method}`" do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.#{method}(:x)
              #{'^' * method.length} #{message}
      RUBY
    end
  end

  argless_builders.each do |method|
    it "registers an offense for a bare `#{method}`" do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.#{method}
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

    it 'accepts `select` with a symbol-to-proc block-pass' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        items.select(&:valid?)
      RUBY
    end

    it 'accepts `select` with a variable block-pass' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        items.select(&block)
      RUBY
    end

    it 'registers an offense for `select` with a column argument' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.select(:id, :status)
              ^^^^^^ #{message}
      RUBY
    end

    it 'registers an offense for `select` with a column and a block-pass' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.select(:id, &formatter)
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

    it 'accepts `references` as a `has_many`' do
      expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
        candidate.references
        job_application.references.create(name: name)
      RUBY
    end

    it 'registers an offense for `references` with arguments' do
      expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
        Order.references(:customer)
              ^^^^^^^^^^ #{message}
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

  describe 'ForbiddenMethods' do
    context 'when configured' do
      let(:config) do
        RuboCop::Config.new(
          'FussyPedant/Rails/NoInlineQuery' => { 'ForbiddenMethods' => ['pluck'] },
          'AllCops' => { 'DisplayCopNames' => true }
        )
      end

      it 'registers an offense for a configured method' do
        expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
          Order.pending.pluck(:email)
                        ^^^^^ #{message}
        RUBY
      end

      it 'replaces rather than extends the default list' do
        expect_no_offenses(<<~RUBY, 'app/controllers/orders_controller.rb')
          Order.where(status: :pending)
        RUBY
      end
    end

    context 'when absent' do
      let(:config) do
        RuboCop::Config.new(
          'FussyPedant/Rails/NoInlineQuery' => { 'Enabled' => true },
          'AllCops' => { 'DisplayCopNames' => true }
        )
      end

      it 'falls back to the default list rather than reporting nothing' do
        expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
          Order.where(status: :pending)
                ^^^^^ #{message}
        RUBY
      end
    end

    context 'when empty' do
      let(:config) do
        RuboCop::Config.new(
          'FussyPedant/Rails/NoInlineQuery' => { 'ForbiddenMethods' => [] },
          'AllCops' => { 'DisplayCopNames' => true }
        )
      end

      it 'falls back to the default list rather than reporting nothing' do
        expect_offense(<<~RUBY, 'app/controllers/orders_controller.rb')
          Order.where(status: :pending)
                ^^^^^ #{message}
        RUBY
      end
    end
  end

  describe 'directory scoping' do
    # The shipped configuration itself, so these examples exercise the
    # `Include`/`Exclude` shape consumers actually get.
    let(:shipped) do
      YAML.load_file('config/default.yml')['FussyPedant/Rails/NoInlineQuery']
    end

    let(:config) do
      RuboCop::Config.new(
        'FussyPedant/Rails/NoInlineQuery' => shipped,
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

    it 'accepts a query in a policy' do
      expect_no_offenses(query, 'app/policies/order_policy.rb')
    end

    it 'accepts a query in a helper' do
      expect_no_offenses(query, 'app/helpers/orders_helper.rb')
    end

    it 'accepts a query in a view component' do
      expect_no_offenses(query, 'app/components/orders/table_component.rb')
    end

    it 'accepts a query in a migration' do
      expect_no_offenses(query, 'db/migrate/20260101000000_backfill.rb')
    end

    it 'accepts a query outside app/ and lib/' do
      expect_no_offenses(query, 'spec/models/order_spec.rb')
      expect_no_offenses(query, 'config/initializers/orders.rb')
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

    it 'registers an offense in lib' do
      expect_offense(<<~RUBY, 'lib/reporting/order_export.rb')
        Order.where(status: :pending)
              ^^^^^ #{message}
      RUBY
    end

    # An engine puts `app/` and `lib/` under a prefix, so both keys need
    # their leading `**/` for engine code to be in scope at all and for
    # an engine's model layer to be back out of it.
    it 'accepts a query in an engine model' do
      expect_no_offenses(query, 'engines/billing/app/models/invoice.rb')
    end

    it 'accepts a query in an engine policy' do
      expect_no_offenses(query, 'engines/billing/app/policies/invoice_policy.rb')
    end

    it 'registers an offense in an engine controller' do
      expect_offense(<<~RUBY, 'engines/billing/app/controllers/invoices_controller.rb')
        Order.where(status: :pending)
              ^^^^^ #{message}
      RUBY
    end

    it 'registers an offense in an engine lib' do
      expect_offense(<<~RUBY, 'engines/billing/lib/billing/calc.rb')
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

  it 'limits the cop to app/ and lib/ in config/default.yml' do
    defaults = YAML.load_file('config/default.yml')
    included = defaults['FussyPedant/Rails/NoInlineQuery']['Include']

    expect(included).to eq(['**/app/**/*.rb', '**/lib/**/*.rb'])
  end

  it 'excludes the directories the design names in config/default.yml' do
    defaults = YAML.load_file('config/default.yml')
    excluded = defaults['FussyPedant/Rails/NoInlineQuery']['Exclude']

    expect(excluded).to eq(
      [
        '**/app/models/**/*', '**/app/queries/**/*', '**/app/policies/**/*',
        '**/app/helpers/**/*', '**/app/components/**/*', '**/db/**/*'
      ]
    )
  end
end
