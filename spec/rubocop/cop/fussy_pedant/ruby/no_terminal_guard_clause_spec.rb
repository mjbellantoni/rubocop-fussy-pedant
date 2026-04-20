# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::NoTerminalGuardClause, :config do
  let(:config) { RuboCop::Config.new }

  context 'with a single guard clause before the final expression' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def foo
          return [] if items.empty?
          ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
          items.sort
        end
      RUBY
    end
  end

  context 'when there is no guard clause' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def foo
          items.sort
        end
      RUBY
    end
  end

  context 'when using if/else already' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def foo
          if items.empty?
            []
          else
            items.sort
          end
        end
      RUBY
    end
  end

  context 'when the guard clause is early (not terminal)' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def foo
          return [] if items.empty?
          intermediate = transform(items)
          intermediate.sort
        end
      RUBY
    end
  end

  context 'when the guard is the last statement (no final expression after it)' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def foo
          do_stuff
          return [] if items.empty?
        end
      RUBY
    end
  end

  context 'when the method has only one statement' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def foo
          items.first
        end
      RUBY
    end
  end

  context 'with multiple consecutive guard clauses before the final expression' do
    it 'registers an offense on the first guard' do
      expect_offense(<<~RUBY)
        def foo
          return [] if items.empty?
          ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `case/when` instead of guard clauses before the final expression.
          return [:default] if use_defaults?
          items.sort
        end
      RUBY
    end
  end

  context 'with three guard clauses' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        def foo
          return :a if cond_a?
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `case/when` instead of guard clauses before the final expression.
          return :b if cond_b?
          return :c if cond_c?
          default_value
        end
      RUBY
    end
  end

  context 'when inside a lambda' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        handler = -> {
          return nil if x.blank?
          x.process
        }
      RUBY
    end
  end

  context 'when inside a block' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        items.map do |item|
          return nil if item.nil?
          item.process
        end
      RUBY
    end
  end

  context 'when inside a proc' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        p = proc {
          return nil if x.nil?
          x.to_s
        }
      RUBY
    end
  end

  context 'when the final expression is a control structure' do
    it 'does not register an offense when final expression is an if' do
      expect_no_offenses(<<~RUBY)
        def foo
          return [] if items.empty?
          if admin?
            admin_items
          else
            regular_items
          end
        end
      RUBY
    end

    it 'does not register an offense when final expression is an unless' do
      expect_no_offenses(<<~RUBY)
        def foo
          return [] if items.empty?
          unless blocked?
            perform_action
          end
        end
      RUBY
    end

    it 'does not register an offense when final expression is a case' do
      expect_no_offenses(<<~RUBY)
        def foo
          return [] if items.empty?
          case role
          when :admin
            admin_items
          else
            regular_items
          end
        end
      RUBY
    end

    it 'still registers an offense when final expression is a ternary' do
      expect_offense(<<~RUBY)
        def foo
          return [] if items.empty?
          ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
          admin? ? admin_items : regular_items
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    context 'when a single guard clause is present' do
      it 'corrects to if/else' do
        expect_offense(<<~RUBY)
          def foo
            return [] if items.empty?
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            if items.empty?
              []
            else
              items.sort
            end
          end
        RUBY
      end
    end

    context 'when the guard has a multi-word return value' do
      it 'corrects to if/else' do
        expect_offense(<<~RUBY)
          def foo
            return { error: 'not found' } if missing?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
            build_response(data)
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            if missing?
              { error: 'not found' }
            else
              build_response(data)
            end
          end
        RUBY
      end
    end

    context 'when inside an indented method' do
      it 'preserves indentation' do
        expect_offense(<<~RUBY)
          class Foo
            def bar
              return [] if items.empty?
              ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
              items.sort
            end
          end
        RUBY

        expect_correction(<<~RUBY)
          class Foo
            def bar
              if items.empty?
                []
              else
                items.sort
              end
            end
          end
        RUBY
      end
    end

    context 'when the final expression is multi-line' do
      it 'corrects preserving the multi-line expression' do
        expect_offense(<<~RUBY)
          def foo
            return [] if items.empty?
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
            items
              .sort
              .uniq
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            if items.empty?
              []
            else
              items
                .sort
                .uniq
            end
          end
        RUBY
      end
    end

    context 'when two guard clauses are present' do
      it 'corrects to case/when' do
        expect_offense(<<~RUBY)
          def foo
            return [] if items.empty?
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `case/when` instead of guard clauses before the final expression.
            return [:default] if use_defaults?
            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            case
            when items.empty?
              []
            when use_defaults?
              [:default]
            else
              items.sort
            end
          end
        RUBY
      end
    end

    context 'when three guard clauses are present' do
      it 'corrects to case/when' do
        expect_offense(<<~RUBY)
          def foo
            return :a if cond_a?
            ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `case/when` instead of guard clauses before the final expression.
            return :b if cond_b?
            return :c if cond_c?
            default_value
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            case
            when cond_a?
              :a
            when cond_b?
              :b
            when cond_c?
              :c
            else
              default_value
            end
          end
        RUBY
      end
    end
  end

  context 'when guard uses bare return and Style/GuardClause is enabled' do
    it 'does not register an offense to avoid autocorrect cycle' do
      expect_no_offenses(<<~RUBY)
        def foo
          return if items.empty?
          items.sort
        end
      RUBY
    end

    it 'does not register an offense with multiple bare-return guards' do
      expect_no_offenses(<<~RUBY)
        def foo
          return if items.empty?
          return if items.frozen?
          items.sort
        end
      RUBY
    end

    it 'still registers an offense when guard returns a value' do
      expect_offense(<<~RUBY)
        def foo
          return [] if items.empty?
          ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
          items.sort
        end
      RUBY
    end
  end

  context 'when guard uses bare return and Style/GuardClause is disabled' do
    let(:config) do
      RuboCop::Config.new(
        'FussyPedant/Ruby/NoTerminalGuardClause' => { 'Enabled' => true },
        'Style/GuardClause' => { 'Enabled' => false }
      )
    end

    it 'corrects bare return if to unless without else' do
      expect_offense(<<~RUBY)
        def foo
          return if items.empty?
          ^^^^^^^^^^^^^^^^^^^^^^ Use `if/else` instead of a guard clause before the final expression.
          items.sort
        end
      RUBY

      expect_correction(<<~RUBY)
        def foo
          unless items.empty?
            items.sort
          end
        end
      RUBY
    end

    it 'corrects bare return unless to if without else' do
      expect_offense(<<~RUBY)
        def foo
          return unless items.present?
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `if/else` instead of a guard clause before the final expression.
          items.sort
        end
      RUBY

      expect_correction(<<~RUBY)
        def foo
          if items.present?
            items.sort
          end
        end
      RUBY
    end
  end

  context 'with edge cases' do

    context 'when guard uses unless' do
      it 'registers an offense and corrects with flipped branches' do
        expect_offense(<<~RUBY)
          def foo
            return [] unless items.present?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            if items.present?
              items.sort
            else
              []
            end
          end
        RUBY
      end
    end

    context 'when unless is mixed with if in multiple guards' do
      it 'corrects unless with negated condition in case/when' do
        expect_offense(<<~RUBY)
          def foo
            return [] unless items.present?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `case/when` instead of guard clauses before the final expression.
            return [:default] if use_defaults?
            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            case
            when !items.present?
              []
            when use_defaults?
              [:default]
            else
              items.sort
            end
          end
        RUBY
      end
    end

    context 'when body is a single expression (no begin node)' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          def foo
            return [] if items.empty?
          end
        RUBY
      end
    end

    context 'with class method (defs)' do
      it 'registers an offense and corrects' do
        expect_offense(<<~RUBY)
          def self.foo
            return [] if items.empty?
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def self.foo
            if items.empty?
              []
            else
              items.sort
            end
          end
        RUBY
      end
    end

    context 'when guard and final expression have a blank line between them' do
      it 'registers an offense and corrects' do
        expect_offense(<<~RUBY)
          def foo
            return [] if items.empty?
            ^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.

            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            if items.empty?
              []
            else
              items.sort
            end
          end
        RUBY
      end
    end

    context 'when a non-guard statement separates guards' do
      it 'only flags the terminal guard and corrects it' do
        expect_offense(<<~RUBY)
          def foo
            return [] if items.empty?
            log_something
            return [:default] if use_defaults?
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoTerminalGuardClause: Use `if/else` instead of a guard clause before the final expression.
            items.sort
          end
        RUBY

        expect_correction(<<~RUBY)
          def foo
            return [] if items.empty?
            log_something
            if use_defaults?
              [:default]
            else
              items.sort
            end
          end
        RUBY
      end
    end
  end
end
