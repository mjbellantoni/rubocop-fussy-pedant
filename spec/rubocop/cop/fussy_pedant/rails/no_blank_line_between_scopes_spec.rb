# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::NoBlankLineBetweenScopes, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a blank line between two scopes' do
    expect_offense(<<~RUBY)
      class User < ApplicationRecord
        scope :active, -> { where(active: true) }

        scope :recent, -> { order(created_at: :desc) }
        ^^^^^^^^^^^^^ FussyPedant/Rails/NoBlankLineBetweenScopes: Do not separate scope declarations with blank lines.
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


        scope :recent, -> { order(created_at: :desc) }
        ^^^^^^^^^^^^^ FussyPedant/Rails/NoBlankLineBetweenScopes: Do not separate scope declarations with blank lines.
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

        scope :hidden, -> { where(hidden: true) }
        ^^^^^^^^^^^^^ FussyPedant/Rails/NoBlankLineBetweenScopes: Do not separate scope declarations with blank lines.

        scope :recent, -> { order(created_at: :desc) }
        ^^^^^^^^^^^^^ FussyPedant/Rails/NoBlankLineBetweenScopes: Do not separate scope declarations with blank lines.
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
        scope :recent, lambda {
          order(created_at: :desc)
        }

        scope :active, -> { where(active: true) }
        ^^^^^^^^^^^^^ FussyPedant/Rails/NoBlankLineBetweenScopes: Do not separate scope declarations with blank lines.
      end
    RUBY

    expect_correction(<<~RUBY)
      class User < ApplicationRecord
        scope :recent, lambda {
          order(created_at: :desc)
        }
        scope :active, -> { where(active: true) }
      end
    RUBY
  end

  it 'registers an offense for scopes inside an included block' do
    expect_offense(<<~RUBY)
      module Archivable
        extend ActiveSupport::Concern

        included do
          scope :archived, -> { where.not(archived_at: nil) }

          scope :unarchived, -> { where(archived_at: nil) }
          ^^^^^^^^^^^^^^^^^ FussyPedant/Rails/NoBlankLineBetweenScopes: Do not separate scope declarations with blank lines.
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
end
