# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::MigrationNameVerb, :config do
  let(:config) do
    RuboCop::Config.new(
      'FussyPedant/Rails/MigrationNameVerb' => {
        'Verbs' => %w[Add Remove Create Backfill]
      }
    )
  end

  it 'registers an offense for a non-verb migration name' do
    expect_offense(<<~RUBY)
      class KeyLeaseAgreementUniquenessOnTenancySpan < ActiveRecord::Migration[7.1]
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Migration class name should start with a verb (e.g. `Add`, `Remove`, `Create`).
      end
    RUBY
  end

  it 'accepts a name starting with a verb' do
    expect_no_offenses(<<~RUBY)
      class AddKeyLeaseAgreementUniquenessOnTenancySpan < ActiveRecord::Migration[7.1]
      end
    RUBY
  end

  it 'accepts other configured verbs' do
    expect_no_offenses(<<~RUBY)
      class BackfillUserNames < ActiveRecord::Migration[7.1]
      end
    RUBY
  end
end
