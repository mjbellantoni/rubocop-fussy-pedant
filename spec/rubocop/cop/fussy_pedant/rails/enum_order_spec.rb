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
end
