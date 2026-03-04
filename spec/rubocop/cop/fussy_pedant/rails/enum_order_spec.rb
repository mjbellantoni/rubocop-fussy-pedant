# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::EnumOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when not an enum call' do
    it 'does not register an offense for non-enum methods' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          validates :name, presence: true
        end
      RUBY
    end
  end

  context 'when using old enum syntax' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          enum status: { draft: 0, published: 1 }
        end
      RUBY
    end
  end

  context 'with alphabetical ordering' do
    context 'with hash form' do
      it 'does not register an offense when values are alphabetical' do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            enum :status, {
              archived: 0,
              draft: 1,
              published: 2
            }
          end
        RUBY
      end

      it 'registers an offense when values are not alphabetical' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            enum :status, {
              draft: 0,
              published: 1,
              archived: 2
              ^^^^^^^^^^^ FussyPedant/Rails/EnumOrder: Enum values should be in alphabetical order. Expected `archived` before `published`.
            }
          end
        RUBY
      end

      it 'registers an offense for each out-of-order pair' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            enum :status, {
              zebra: 0,
              beta: 1,
              ^^^^^^^ FussyPedant/Rails/EnumOrder: Enum values should be in alphabetical order. Expected `beta` before `zebra`.
              alpha: 2
              ^^^^^^^^ FussyPedant/Rails/EnumOrder: Enum values should be in alphabetical order. Expected `alpha` before `beta`.
            }
          end
        RUBY
      end
    end

    context 'with array form' do
      it 'does not register an offense when values are alphabetical' do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            enum :status, [
              :archived,
              :draft,
              :published
            ]
          end
        RUBY
      end

      it 'registers an offense when values are not alphabetical' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            enum :status, [
              :draft,
              :published,
              :archived
              ^^^^^^^^^ FussyPedant/Rails/EnumOrder: Enum values should be in alphabetical order. Expected `archived` before `published`.
            ]
          end
        RUBY
      end
    end

    context 'with %i form' do
      it 'does not register an offense when values are alphabetical' do
        expect_no_offenses(<<~RUBY)
          class User < ApplicationRecord
            enum :status, %i[
              archived
              draft
              published
            ]
          end
        RUBY
      end

      it 'registers an offense when values are not alphabetical' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            enum :status, %i[
              draft
              published
              archived
              ^^^^^^^^ FussyPedant/Rails/EnumOrder: Enum values should be in alphabetical order. Expected `archived` before `published`.
            ]
          end
        RUBY
      end
    end

    context 'with %w form' do
      it 'registers an offense when values are not alphabetical' do
        expect_offense(<<~RUBY)
          class User < ApplicationRecord
            enum :status, %w[
              draft
              published
              archived
              ^^^^^^^^ FussyPedant/Rails/EnumOrder: Enum values should be in alphabetical order. Expected `archived` before `published`.
            ]
          end
        RUBY
      end
    end
  end

  context 'with one-per-line formatting' do
    it 'does not register an offense when values are one per line' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          enum :status, {
            archived: 0,
            draft: 1,
            published: 2
          }
        end
      RUBY
    end

    it 'registers an offense when hash values are on one line' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          enum :status, { archived: 0, draft: 1, published: 2 }
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/EnumOrder: Each enum value should be on its own line.
        end
      RUBY
    end

    it 'registers an offense when array values are on one line' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          enum :status, [:archived, :draft, :published]
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/EnumOrder: Each enum value should be on its own line.
        end
      RUBY
    end

    it 'registers an offense when %i values are on one line' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          enum :status, %i[archived draft published]
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/EnumOrder: Each enum value should be on its own line.
        end
      RUBY
    end

    it 'registers an offense when some values share a line' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          enum :status, {
                        ^ FussyPedant/Rails/EnumOrder: Each enum value should be on its own line.
            archived: 0, draft: 1,
            published: 2
          }
        end
      RUBY
    end

    it 'does not register an offense for a single value on one line' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          enum :status, {
            active: 0
          }
        end
      RUBY
    end
  end
end
