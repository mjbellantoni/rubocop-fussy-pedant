# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::NoSingleLineCaseBody, :config do
  let(:config) { RuboCop::Config.new }

  context 'when when body is on the same line' do
    it 'registers an offense for when with then' do
      expect_offense(<<~RUBY)
        case foo
        when 1 then :dingus
        ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        end
      RUBY
    end

    it 'registers an offense for multiple single-line whens' do
      expect_offense(<<~RUBY)
        case foo
        when 1 then :dingus
        ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        when 2 then :freebus
        ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        end
      RUBY
    end
  end

  context 'when else body is on the same line' do
    it 'registers an offense for single-line else' do
      expect_offense(<<~RUBY)
        case foo
        when 1
          :dingus
        else :ding
        ^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `else` to the next line.
        end
      RUBY
    end
  end

  context 'when bodies are on the next line' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        case foo
        when 1
          :dingus
        when 2
          :freebus
        else
          :ding
        end
      RUBY
    end
  end

  context 'when when has no body' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        case foo
        when 1
        when 2
          :freebus
        end
      RUBY
    end
  end

  context 'when else has no body' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        case foo
        when 1
          :dingus
        else
        end
      RUBY
    end
  end

  context 'with when having multiple conditions' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        case foo
        when 1, 2 then :dingus
        ^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    it 'moves when body to next line and removes then' do
      expect_offense(<<~RUBY)
        case foo
        when 1 then :dingus
        ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        end
      RUBY

      expect_correction(<<~RUBY)
        case foo
        when 1
          :dingus
        end
      RUBY
    end

    it 'moves else body to next line' do
      expect_offense(<<~RUBY)
        case foo
        when 1
          :dingus
        else :ding
        ^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `else` to the next line.
        end
      RUBY

      expect_correction(<<~RUBY)
        case foo
        when 1
          :dingus
        else
          :ding
        end
      RUBY
    end

    it 'corrects a full case statement' do
      expect_offense(<<~RUBY)
        case foo
        when 1 then :dingus
        ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        when 2 then :freebus
        ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
        else :ding
        ^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `else` to the next line.
        end
      RUBY

      expect_correction(<<~RUBY)
        case foo
        when 1
          :dingus
        when 2
          :freebus
        else
          :ding
        end
      RUBY
    end

    it 'preserves indentation in nested context' do
      expect_offense(<<~RUBY)
        def bar
          case foo
          when 1 then :dingus
          ^^^^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoSingleLineCaseBody: Move the body of `when` to the next line.
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        def bar
          case foo
          when 1
            :dingus
          end
        end
      RUBY
    end
  end
end
