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
end
