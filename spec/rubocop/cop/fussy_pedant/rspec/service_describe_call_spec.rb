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

  context 'when describe .call has hooks and siblings' do
    it 'registers an offense but does not autocorrect when before would leak' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            before { create(:record) }

            it 'does something' do; end
          end

          context 'with errors' do
            before { create(:error_record) }

            it 'handles errors' do; end
          end
        end
      RUBY

      expect_no_corrections
    end

    it 'registers an offense but does not autocorrect when after would leak' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            after { cleanup }

            it 'does something' do; end
          end

          context 'with errors' do
            it 'handles errors' do; end
          end
        end
      RUBY

      expect_no_corrections
    end

    it 'registers an offense but does not autocorrect when around would leak' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            around { |ex| Timecop.freeze { ex.run } }

            it 'does something' do; end
          end

          context 'with errors' do
            it 'handles errors' do; end
          end
        end
      RUBY

      expect_no_corrections
    end

    it 'still autocorrects when describe .call has hooks but no siblings' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            before { create(:record) }

            it 'does something' do; end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe MyService do
          before { create(:record) }

          it 'does something' do; end
        end
      RUBY
    end

    it 'still autocorrects when describe .call has siblings but no hooks' do
      expect_offense(<<~RUBY)
        RSpec.describe MyService do
          describe '.call' do
          ^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ServiceDescribeCall: Remove redundant `describe '.call'` — service specs test a single method.
            it 'does something' do; end
          end

          context 'with errors' do
            it 'handles errors' do; end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe MyService do
          it 'does something' do; end
          context 'with errors' do
            it 'handles errors' do; end
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
