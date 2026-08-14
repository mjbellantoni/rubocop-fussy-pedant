# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::SinglePrivateClassMethod, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense and splits multiple names' do
    expect_offense(<<~RUBY)
      private_class_method :env_ignored_entries, :ignored_domains
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/SinglePrivateClassMethod: Use a separate `private_class_method` directive for each method.
    RUBY
    expect_correction(<<~RUBY)
      private_class_method :env_ignored_entries
      private_class_method :ignored_domains
    RUBY
  end

  it 'preserves indentation when splitting' do
    expect_offense(<<~RUBY)
      class Foo
        private_class_method :a, :b
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/SinglePrivateClassMethod: Use a separate `private_class_method` directive for each method.
      end
    RUBY
    expect_correction(<<~RUBY)
      class Foo
        private_class_method :a
        private_class_method :b
      end
    RUBY
  end

  it 'handles mixed symbol and string names' do
    expect_offense(<<~RUBY)
      private_class_method :a, 'b'
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/SinglePrivateClassMethod: Use a separate `private_class_method` directive for each method.
    RUBY
    expect_correction(<<~RUBY)
      private_class_method :a
      private_class_method 'b'
    RUBY
  end

  it 'accepts a single name' do
    expect_no_offenses('private_class_method :a')
  end

  it 'ignores the def form' do
    expect_no_offenses('private_class_method def self.foo; end')
  end
end
