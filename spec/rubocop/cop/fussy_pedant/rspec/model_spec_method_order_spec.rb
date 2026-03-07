# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::RSpec::ModelSpecMethodOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when describes are in correct order' do
    it 'does not register an offense for class methods then instance methods' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '.active' do; end
          describe '.search' do; end
          describe '#admin?' do; end
          describe '#full_name' do; end
        end
      RUBY
    end

    it 'does not register an offense for only class methods alphabetical' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '.active' do; end
          describe '.search' do; end
        end
      RUBY
    end

    it 'does not register an offense for only instance methods alphabetical' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '#admin?' do; end
          describe '#full_name' do; end
        end
      RUBY
    end

    it 'does not register an offense for a single describe' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '.active' do; end
        end
      RUBY
    end
  end

  context 'when describes are out of order' do
    it 'registers an offense when instance method comes before class method' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#full_name' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected class method `.search` to come before instance method `#full_name`.
          describe '.search' do; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `#full_name` to come before `.search` (alphabetical order).
        end
      RUBY
    end

    it 'registers an offense for class methods out of alphabetical order' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '.search' do; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `.active` to come before `.search` (alphabetical order).
          describe '.active' do; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `.search` to come before `.active` (alphabetical order).
        end
      RUBY
    end

    it 'registers an offense for instance methods out of alphabetical order' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#full_name' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `#admin?` to come before `#full_name` (alphabetical order).
          describe '#admin?' do; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `#full_name` to come before `#admin?` (alphabetical order).
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

    it 'ignores non-method describe blocks' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe 'validations' do; end
          describe '.active' do; end
          describe '#full_name' do; end
        end
      RUBY
    end

    it 'skips non-describe child blocks (context, it, let)' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          let(:user) { build(:user) }

          describe '.active' do; end
          describe '#full_name' do; end
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    it 'reorders class methods before instance methods' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#full_name' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected class method `.search` to come before instance method `#full_name`.
          describe '.search' do; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `#full_name` to come before `.search` (alphabetical order).
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe User do
          describe '.search' do; end

          describe '#full_name' do; end
        end
      RUBY
    end

    it 'sorts all groups correctly' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#full_name' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected class method `.active` to come before instance method `#full_name`.
          describe '.search' do; end
          describe '#admin?' do; end
          describe '.active' do; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/ModelSpecMethodOrder: Expected `#full_name` to come before `.active` (alphabetical order).
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe User do
          describe '.active' do; end

          describe '.search' do; end

          describe '#admin?' do; end

          describe '#full_name' do; end
        end
      RUBY
    end
  end
end
