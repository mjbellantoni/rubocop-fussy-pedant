# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::ServiceCallPattern, :config do
  let(:config) { RuboCop::Config.new }

  context 'when service conforms to pattern' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def initialize(foo:, bar:)
            @foo = foo
            @bar = bar
          end

          def call
            perform_work
          end

          private

          def perform_work
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service is missing .call class method' do
    it 'registers an offense' do
      expect_offense(<<~RUBY, '/app/services/my_service.rb')
        class MyService
        ^^^^^^^^^^^^^^^ FussyPedant/Rails/ServiceCallPattern: Service objects must implement `def self.call(...)`
          def initialize(foo:)
            @foo = foo
          end

          def perform
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service has custom class method instead of .call' do
    it 'registers offense for missing .call' do
      expect_offense(<<~RUBY, '/app/services/my_service.rb')
        class MyService
        ^^^^^^^^^^^^^^^ FussyPedant/Rails/ServiceCallPattern: Service objects must implement `def self.call(...)`
          def self.perform(foo:)
            new(foo: foo).perform
          end

          def initialize(foo:)
            @foo = foo
          end

          def perform
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service has both .call and custom class methods' do
    it 'registers an offense for the custom method' do
      expect_offense(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def self.legacy_method(foo:)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ServiceCallPattern: Service objects should only expose .call class method, found: legacy_method
            new(foo: foo).call
          end

          def initialize(foo:)
            @foo = foo
          end

          def call
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service has wrong instance method name' do
    it 'registers an offense' do
      expect_offense(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def initialize(foo:)
            @foo = foo
          end

          def perform
          ^^^^^^^^^^^ FussyPedant/Rails/ServiceCallPattern: Service instance method must be named 'call', found: perform
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service methods are in wrong order' do
    it 'registers an offense when initialize comes before self.call' do
      expect_offense(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def initialize(foo:)
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ServiceCallPattern: Service methods must be ordered: self.call, initialize, call, private
            @foo = foo
          end

          def self.call(...)
            new(...).call
          end

          def call
            "result"
          end
        end
      RUBY
    end

    it 'registers an offense when call comes before initialize' do
      expect_offense(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def call
          ^^^^^^^^ FussyPedant/Rails/ServiceCallPattern: Service methods must be ordered: self.call, initialize, call, private
            "result"
          end

          def initialize(foo:)
            @foo = foo
          end
        end
      RUBY
    end
  end

  context 'when service is directly instantiated in production code' do
    it 'does not register offense for stdlib classes' do
      expect_no_offenses(<<~RUBY, '/app/controllers/users_controller.rb')
        class UsersController
          def create
            StringIO.new("content")
          end
        end
      RUBY
    end

    it 'does not register offense for non-existent service classes' do
      expect_no_offenses(<<~RUBY, '/app/controllers/users_controller.rb')
        class UsersController
          def create
            MyService.new(foo: params[:foo]).call
          end
        end
      RUBY
    end

    it 'does not register offense for .new in service own .call method' do
      expect_no_offenses(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def initialize(foo:)
            @foo = foo
          end

          def call
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service is instantiated in spec file' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, '/spec/services/my_service_spec.rb')
        RSpec.describe MyService do
          it "works" do
            service = MyService.new(foo: "bar")
            expect(service.call).to eq("result")
          end
        end
      RUBY
    end
  end

  context 'when file contains a module, not a class' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        module MyHelpers
          def helper_method
            "result"
          end
        end
      RUBY
    end
  end

  context 'when service has private methods' do
    it 'does not flag private methods as needing to be named call' do
      expect_no_offenses(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def initialize(foo:)
            @foo = foo
          end

          def call
            helper_method
          end

          private

          def helper_method
            "result"
          end

          def another_helper
            "more"
          end
        end
      RUBY
    end
  end

  context 'when service has correct order with private methods' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          def self.call(...)
            new(...).call
          end

          def initialize(foo:, bar:)
            @foo = foo
            @bar = bar
          end

          def call
            process_foo + process_bar
          end

          private

          attr_reader :foo
          attr_reader :bar

          def process_foo
            foo.upcase
          end

          def process_bar
            bar.downcase
          end
        end
      RUBY
    end
  end

  context 'when file contains exception classes' do
    it 'does not register offense for exception classes in service files' do
      expect_no_offenses(<<~RUBY, '/app/services/my_service.rb')
        class MyService
          class CustomError < StandardError; end
          class AnotherError < ArgumentError; end

          def self.call(...)
            new(...).call
          end

          def initialize(foo:)
            @foo = foo
          end

          def call
            raise CustomError if @foo.nil?
            "result"
          end
        end
      RUBY
    end
  end

  context 'when class is outside app/services/' do
    it 'does not register offense for classes outside app/services/' do
      expect_no_offenses(<<~RUBY, '/app/models/user.rb')
        class User
          def initialize(name:)
            @name = name
          end

          def greet
            @name
          end
        end
      RUBY
    end
  end
end
