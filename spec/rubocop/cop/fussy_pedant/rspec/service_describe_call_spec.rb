# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::RSpec::ServiceDescribeCall, :config do
  let(:config) { RuboCop::Config.new }

  context 'when describe .call is nested' do
    it 'registers an offense for describe .call' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            it 'does something' do; end
          end
        end
      RUBY
    end

    it 'registers an offense for describe #call' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '#call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '#call'` — service specs test a single method.
            it 'does something' do; end
          end
        end
      RUBY
    end
  end

  context 'when spec is correctly structured' do
    it 'does not register an offense when examples are direct children' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe MyService do
          it 'does something' do; end
        end
      RUBY
    end

    it 'does not register an offense for non-call describe blocks' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe MyService do
          describe 'when input is invalid' do
            it 'raises an error' do; end
          end
        end
      RUBY
    end

    it 'does not register an offense for nested context blocks' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe MyService do
          context 'when valid' do
            it 'succeeds' do; end
          end
        end
      RUBY
    end
  end

  context 'with edge cases' do
    it 'does not register an offense for empty describe blocks' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe MyService do
        end
      RUBY
    end

    it 'does not flag describe .call that is not a direct child' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe MyService do
          context 'when valid' do
            describe '.call' do
              it 'works' do; end
            end
          end
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    it 'unwraps describe .call and promotes children' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            it 'does something' do; end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe MyService do
          it 'does something' do; end
        end
      RUBY
    end

    it 'unwraps describe .call with multiple children' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            let(:input) { 'foo' }

            it 'does something' do; end

            context 'when invalid' do
              it 'raises' do; end
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe MyService do
          let(:input) { 'foo' }

          it 'does something' do; end

          context 'when invalid' do
            it 'raises' do; end
          end
        end
      RUBY
    end

    it 'removes empty describe .call block' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe MyService do
        end
      RUBY
    end
  end
end
