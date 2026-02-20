# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::FactoryBot::TraitsAlphabeticalOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when traits are in alphabetical order' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
            trait :admin do
              role { 'admin' }
            end

            trait :with_posts do
              posts { build_list(:post, 3) }
            end
          end
        end
      RUBY
    end
  end

  context 'when traits are not in alphabetical order' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
            trait :with_posts do
              posts { build_list(:post, 3) }
            end

            trait :admin do
            ^^^^^^^^^^^^ FussyPedant/FactoryBot/TraitsAlphabeticalOrder: Traits should be defined in alphabetical order. Expected `with_posts` to come before `admin`.
              role { 'admin' }
            end
          end
        end
      RUBY
    end
  end

  context 'when factory has only one trait' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
            trait :admin do
              role { 'admin' }
            end
          end
        end
      RUBY
    end
  end

  context 'when factory has no traits' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
            name { 'John' }
          end
        end
      RUBY
    end
  end

  context 'when there are multiple out-of-order traits' do
    it 'registers offenses for each misordered pair' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
            trait :zulu do
              # ...
            end

            trait :bravo do
            ^^^^^^^^^^^^ FussyPedant/FactoryBot/TraitsAlphabeticalOrder: Traits should be defined in alphabetical order. Expected `zulu` to come before `bravo`.
              # ...
            end

            trait :alpha do
            ^^^^^^^^^^^^ FussyPedant/FactoryBot/TraitsAlphabeticalOrder: Traits should be defined in alphabetical order. Expected `bravo` to come before `alpha`.
              # ...
            end
          end
        end
      RUBY
    end
  end

  context 'when traits are mixed with other factory content' do
    it 'only checks trait ordering' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user do
            name { 'John' }

            trait :admin do
              role { 'admin' }
            end

            sequence(:email) { |n| "user\#{n}@example.com" }

            trait :with_posts do
              posts { build_list(:post, 3) }
            end
          end
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    it 'sorts traits alphabetically' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user do
            trait :with_posts do
              posts { build_list(:post, 3) }
            end

            trait :admin do
            ^^^^^^^^^^^^ FussyPedant/FactoryBot/TraitsAlphabeticalOrder: Traits should be defined in alphabetical order. Expected `with_posts` to come before `admin`.
              role { 'admin' }
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :user do
            trait :admin do
              role { 'admin' }
            end

            trait :with_posts do
              posts { build_list(:post, 3) }
            end
          end
        end
      RUBY
    end
  end

  context 'when not inside a factory block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        some_method do
          trait :zebra do
          end
          trait :alpha do
          end
        end
      RUBY
    end
  end
end
