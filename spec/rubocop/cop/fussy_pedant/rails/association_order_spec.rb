# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::AssociationOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when there are fewer than 2 associations' do
    it 'does not register an offense for a single association' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          belongs_to :company
        end
      RUBY
    end

    it 'does not register an offense for no associations' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          validates :name, presence: true
        end
      RUBY
    end
  end

  context 'with type ordering' do
    it 'does not register an offense when associations are in correct type order' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          belongs_to :company
          has_many :posts
        end
      RUBY
    end

    it 'registers an offense when belongs_to comes after has_many' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          has_many :posts
          belongs_to :company
          ^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/AssociationOrder: Expected `belongs_to :company` to come after `has_many` associations, not before.
        end
      RUBY
    end

    it 'does not register an offense for full correct type order' do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          belongs_to :author
          has_one :metadata
          has_many :comments
          has_and_belongs_to_many :tags
        end
      RUBY
    end

    it 'registers an offense when has_one comes after has_many' do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          has_many :comments
          has_one :metadata
          ^^^^^^^^^^^^^^^^^ FussyPedant/Rails/AssociationOrder: Expected `has_one :metadata` to come after `has_many` associations, not before.
        end
      RUBY
    end

    it 'handles through variants as separate subtypes' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          has_one :profile
          has_one :avatar, through: :profile
          has_many :posts
          has_many :comments, through: :posts
        end
      RUBY
    end

    it 'registers an offense when has_many comes after has_many :through' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          has_many :comments, through: :posts
          has_many :posts
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/AssociationOrder: Expected `has_many :posts` to come after `has_many :through` associations, not before.
        end
      RUBY
    end

    it 'registers an offense when has_one :through comes before has_one' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          has_one :avatar, through: :profile
          has_one :profile
          ^^^^^^^^^^^^^^^^ FussyPedant/Rails/AssociationOrder: Expected `has_one :profile` to come after `has_one :through` associations, not before.
        end
      RUBY
    end

    it 'ignores non-association methods between associations' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          belongs_to :company
          validates :name, presence: true
          has_many :posts
        end
      RUBY
    end
  end
end
