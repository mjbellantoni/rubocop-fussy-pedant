# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::RSpec::ModelSpecDescribeFormat, :config do
  let(:config) { RuboCop::Config.new }

  context 'when describes use method format' do
    it 'does not register an offense for class method format' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '.active' do; end
        end
      RUBY
    end

    it 'does not register an offense for instance method format' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '#full_name' do; end
        end
      RUBY
    end

    it 'does not register an offense for mixed method formats' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '.active' do; end
          describe '#full_name' do; end
        end
      RUBY
    end
  end

  context 'when describes use non-method format' do
    it 'registers an offense for validations' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe 'validations' do; end
          ^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecDescribeFormat: Use `.method` or `#method` format for describe blocks in model specs, not `validations`.
        end
      RUBY
    end

    it 'registers an offense for associations' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe 'associations' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecDescribeFormat: Use `.method` or `#method` format for describe blocks in model specs, not `associations`.
        end
      RUBY
    end

    it 'registers an offense for callbacks' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe 'callbacks' do; end
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecDescribeFormat: Use `.method` or `#method` format for describe blocks in model specs, not `callbacks`.
        end
      RUBY
    end

    it 'registers multiple offenses' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe 'validations' do; end
          ^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecDescribeFormat: Use `.method` or `#method` format for describe blocks in model specs, not `validations`.
          describe '.active' do; end
          describe 'scopes' do; end
          ^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecDescribeFormat: Use `.method` or `#method` format for describe blocks in model specs, not `scopes`.
        end
      RUBY
    end
  end

  context 'with edge cases' do
    it 'does not register an offense for empty describe' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
        end
      RUBY
    end

    it 'does not flag non-describe child blocks' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          context 'when active' do; end
        end
      RUBY
    end

    it 'does not flag nested non-method describes (only direct children)' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '#valid?' do
            describe 'when email is blank' do; end
          end
        end
      RUBY
    end

    it 'does not flag describes with non-string arguments' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe User::Admin do; end
        end
      RUBY
    end
  end
end
