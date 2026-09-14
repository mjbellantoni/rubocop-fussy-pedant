# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::ScopeOrder, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a blank line between two scopes' do
    expect_offense(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }

      ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY

    expect_correction(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'registers an offense for multiple blank lines between two scopes' do
    expect_offense(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }

      ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.

        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY

    expect_correction(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'registers an offense for each blank-separated pair in a run' do
    expect_offense(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }

      ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
        scope :hidden, -> { where(hidden: true) }

      ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY

    expect_correction(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
        scope :hidden, -> { where(hidden: true) }
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'registers an offense after a multiline scope' do
    expect_offense(<<~RUBY)
      class User < ApplicationRecord
        scope :active, lambda {
          where(active: true)
        }

      ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY

    expect_correction(<<~RUBY)
      class User < ApplicationRecord
        scope :active, lambda {
          where(active: true)
        }
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'registers an offense for scopes inside an included block' do
    expect_offense(<<~RUBY)
      module Archivable
        extend ActiveSupport::Concern

        included do
          scope :archived, -> { where.not(archived_at: nil) }

      ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
          scope :unarchived, -> { where(archived_at: nil) }
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      module Archivable
        extend ActiveSupport::Concern

        included do
          scope :archived, -> { where.not(archived_at: nil) }
          scope :unarchived, -> { where(archived_at: nil) }
        end
      end
    RUBY
  end

  it 'accepts adjacent scopes' do
    expect_no_offenses(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'accepts a blank line when a comment separates the scopes' do
    expect_no_offenses(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }

        # Only rows the sales team can see.
        scope :visible, -> { where(hidden: false) }
      end
    RUBY
  end

  it 'accepts a blank line when a trailing comment follows the first scope' do
    expect_no_offenses(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
        # Legacy rows only.

        scope :visible, -> { where(hidden: false) }
      end
    RUBY
  end

  it 'accepts scopes separated by other code' do
    expect_no_offenses(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }

        validates :name, presence: true

        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'accepts a lone scope' do
    expect_no_offenses(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
      end
    RUBY
  end

  it 'accepts scopes in separate classes' do
    expect_no_offenses(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }
      end

      class Post < ApplicationRecord
        scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  it 'ignores a scope call with a receiver' do
    expect_no_offenses(<<~RUBY)
      class Report
        User.scope :active, -> { where(active: true) }

        User.scope :recent, -> { order(created_at: :desc) }
      end
    RUBY
  end

  context 'when scopes are out of alphabetical order' do
    it 'registers an offense and reorders them' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          scope :recent, -> { order(created_at: :desc) }
          scope :active, -> { where(active: true) }
          ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:recent` (alphabetical order).
        end
      RUBY

      expect_correction(<<~RUBY)
        class User < ApplicationRecord
          scope :active, -> { where(active: true) }
          scope :recent, -> { order(created_at: :desc) }
        end
      RUBY
    end

    it 'accepts scopes already in alphabetical order' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          scope :active, -> { where(active: true) }
          scope :hidden, -> { where(hidden: true) }
          scope :recent, -> { order(created_at: :desc) }
        end
      RUBY
    end

    it 'sorts comment-delimited groups independently' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          # Visibility.
          scope :hidden, -> { where(hidden: true) }
          scope :active, -> { where(active: true) }
          ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:hidden` (alphabetical order).

          # Time windows.
          scope :recent, -> { order(created_at: :desc) }
          scope :ancient, -> { order(created_at: :asc) }
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:ancient` to come before `:recent` (alphabetical order).
        end
      RUBY

      expect_correction(<<~RUBY)
        class User < ApplicationRecord
          # Visibility.
          scope :active, -> { where(active: true) }
          scope :hidden, -> { where(hidden: true) }

          # Time windows.
          scope :ancient, -> { order(created_at: :asc) }
          scope :recent, -> { order(created_at: :desc) }
        end
      RUBY
    end

    it 'accepts out-of-order scopes across a comment boundary' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          scope :recent, -> { order(created_at: :desc) }

          # Visibility.
          scope :active, -> { where(active: true) }
        end
      RUBY
    end

    it 'reorders multiline scopes' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          scope :recent, lambda {
            order(created_at: :desc)
          }
          scope :active, -> { where(active: true) }
          ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:recent` (alphabetical order).
        end
      RUBY

      expect_correction(<<~RUBY)
        class User < ApplicationRecord
          scope :active, -> { where(active: true) }
          scope :recent, lambda {
            order(created_at: :desc)
          }
        end
      RUBY
    end

    it 'registers both offenses for an unsorted run with a blank line' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          scope :recent, -> { order(created_at: :desc) }

        ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
          scope :active, -> { where(active: true) }
          ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:recent` (alphabetical order).
        end
      RUBY

      expect_correction(<<~RUBY)
        class User < ApplicationRecord
          scope :active, -> { where(active: true) }
          scope :recent, -> { order(created_at: :desc) }
        end
      RUBY
    end

    it 'does not reorder a run holding a trailing comment' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          scope :recent, -> { order(created_at: :desc) } # Newest first.
          scope :active, -> { where(active: true) }
          ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:recent` (alphabetical order).
        end
      RUBY

      expect_no_corrections
    end

    it 'ignores scopes with interpolated names' do
      expect_no_offenses(<<~'RUBY')
        class User < ApplicationRecord
          scope :recent, -> { order(created_at: :desc) }
          scope :"for_#{role}", -> { where(role: role) }
          scope :active, -> { where(active: true) }
        end
      RUBY
    end

    it 'ignores scopes defined in a loop' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          scope :recent, -> { order(created_at: :desc) }
          ROLES.each { |role| scope role, -> { where(role: role) } }
          scope :active, -> { where(active: true) }
        end
      RUBY
    end
  end

  context 'with configuration' do
    context 'when CheckAlphabetical is false' do
      before do
        allow(cop).to receive(:cop_config).and_return(
          'CheckAlphabetical' => false,
          'CheckSpacing' => true
        )
      end

      it 'does not check alphabetical ordering' do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope :recent, -> { order(created_at: :desc) }
            scope :active, -> { where(active: true) }
          end
        RUBY
      end

      it 'still checks spacing without reordering' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            scope :recent, -> { order(created_at: :desc) }

          ^{} FussyPedant/Rails/ScopeOrder: Do not separate scope declarations with blank lines.
            scope :active, -> { where(active: true) }
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            scope :recent, -> { order(created_at: :desc) }
            scope :active, -> { where(active: true) }
          end
        RUBY
      end
    end

    context 'when CheckSpacing is false' do
      before do
        allow(cop).to receive(:cop_config).and_return(
          'CheckAlphabetical' => true,
          'CheckSpacing' => false
        )
      end

      it 'does not check spacing' do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            scope :active, -> { where(active: true) }

            scope :recent, -> { order(created_at: :desc) }
          end
        RUBY
      end

      it 'still checks alphabetical ordering' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            scope :recent, -> { order(created_at: :desc) }
            scope :active, -> { where(active: true) }
            ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:recent` (alphabetical order).
          end
        RUBY

        expect_correction(<<~RUBY)
          class User < ApplicationRecord
            scope :active, -> { where(active: true) }
            scope :recent, -> { order(created_at: :desc) }
          end
        RUBY
      end

      it 'does not reorder a run that still holds blank lines' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            scope :recent, -> { order(created_at: :desc) }

            scope :active, -> { where(active: true) }
            ^^^^^^^^^^^^^ FussyPedant/Rails/ScopeOrder: Expected `:active` to come before `:recent` (alphabetical order).
          end
        RUBY

        expect_no_corrections
      end
    end
  end
end
