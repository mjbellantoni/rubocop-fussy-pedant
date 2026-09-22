# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::DelegateOrder, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for a delegate naming several methods' do
    expect_offense(<<~RUBY)
      class Message
        delegate :draft_uuid, :context_type, to: :context
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Declare one method per `delegate`.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Message
        delegate :context_type, to: :context
        delegate :draft_uuid, to: :context
      end
    RUBY
  end

  it 'registers an offense for delegates out of alphabetical order' do
    expect_offense(<<~RUBY)
      class Message
        delegate :name, to: :user
        delegate :zip, to: :address
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Expected `:zip` (to: `:address`) to come before `:name` (to: `:user`) (alphabetical by `to:`, then method).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Message
        delegate :zip, to: :address
        delegate :name, to: :user
      end
    RUBY
  end

  it 'splits a delegate whose methods wrap onto a second line' do
    expect_offense(<<~RUBY)
      class Message
        delegate :context_type, :draft_uuid, :mark_done?,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Declare one method per `delegate`.
                 :thread_uuid, :transition_index, to: :context
      end
    RUBY

    expect_correction(<<~RUBY)
      class Message
        delegate :context_type, to: :context
        delegate :draft_uuid, to: :context
        delegate :mark_done?, to: :context
        delegate :thread_uuid, to: :context
        delegate :transition_index, to: :context
      end
    RUBY
  end

  it 'carries every option onto each split declaration' do
    expect_offense(<<~RUBY)
      class Message
        delegate :name, :email, to: :user, prefix: true, allow_nil: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Declare one method per `delegate`.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Message
        delegate :email, to: :user, prefix: true, allow_nil: true
        delegate :name, to: :user, prefix: true, allow_nil: true
      end
    RUBY
  end

  it 'sorts every target together when a run mixes them' do
    expect_offense(<<~RUBY)
      class Message
        delegate :name, :email, to: :user
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Declare one method per `delegate`.
        delegate :zip, to: :address
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Expected `:zip` (to: `:address`) to come before `:email` (to: `:user`) (alphabetical by `to:`, then method).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Message
        delegate :zip, to: :address
        delegate :email, to: :user
        delegate :name, to: :user
      end
    RUBY
  end

  it 'does not register an offense for a sorted run' do
    expect_no_offenses(<<~RUBY)
      class Message
        delegate :zip, to: :address
        delegate :email, to: :user
        delegate :name, to: :user
      end
    RUBY
  end

  it 'does not register an offense when a blank line separates the delegates' do
    expect_no_offenses(<<~RUBY)
      class Message
        delegate :name, to: :user

        delegate :zip, to: :address
      end
    RUBY
  end

  it 'does not register an offense when a comment separates the delegates' do
    expect_no_offenses(<<~RUBY)
      class Message
        delegate :name, to: :user
        # Address details.
        delegate :zip, to: :address
      end
    RUBY
  end

  it 'does not correct a run whose declaration carries a trailing comment' do
    expect_offense(<<~RUBY)
      class Message
        delegate :name, to: :user # legacy
        delegate :zip, to: :address
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Expected `:zip` (to: `:address`) to come before `:name` (to: `:user`) (alphabetical by `to:`, then method).
      end
    RUBY

    expect_no_corrections
  end

  it 'does not register an offense for a splatted method list' do
    expect_no_offenses(<<~RUBY)
      class Message
        delegate :zip, to: :address
        delegate(*CONTEXT_METHODS, to: :context)
        delegate :name, to: :user
      end
    RUBY
  end

  it 'does not register an offense for a delegate without a to: target' do
    expect_no_offenses(<<~RUBY)
      class Message
        delegate :name, :email
      end
    RUBY
  end

  it 'does not register an offense for a visibility-wrapped delegate' do
    expect_no_offenses(<<~RUBY)
      class Message
        private delegate :name, :email, to: :user
      end
    RUBY
  end

  it 'does not register an offense when other code shares a delegate line' do
    expect_no_offenses(<<~RUBY)
      class Message
        delegate :name, to: :user; log(:delegated)
        delegate :zip, to: :address
      end
    RUBY
  end

  it 'sorts delegates declared at the top level of a module' do
    expect_offense(<<~RUBY)
      module Addressable
        delegate :name, to: :user
        delegate :zip, to: :address
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Expected `:zip` (to: `:address`) to come before `:name` (to: `:user`) (alphabetical by `to:`, then method).
      end
    RUBY

    expect_correction(<<~RUBY)
      module Addressable
        delegate :zip, to: :address
        delegate :name, to: :user
      end
    RUBY
  end

  it 'sorts each run of a class separately' do
    expect_offense(<<~RUBY)
      class Message
        delegate :name, to: :user
        delegate :handle, to: :user
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Expected `:handle` (to: `:user`) to come before `:name` (to: `:user`) (alphabetical by `to:`, then method).

        delegate :zip, to: :address
        delegate :city, to: :address
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Expected `:city` (to: `:address`) to come before `:zip` (to: `:address`) (alphabetical by `to:`, then method).
      end
    RUBY

    expect_correction(<<~RUBY)
      class Message
        delegate :handle, to: :user
        delegate :name, to: :user

        delegate :city, to: :address
        delegate :zip, to: :address
      end
    RUBY
  end

  it 'does not correct a delegate whose options span several lines' do
    expect_offense(<<~RUBY)
      class Message
        delegate :name, :email, to: :user,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/DelegateOrder: Declare one method per `delegate`.
                 prefix: true
      end
    RUBY

    expect_no_corrections
  end
end
