# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::RSpec::NoWait, :config do
  let(:config) { RuboCop::Config.new }

  context 'with sleep' do
    it 'registers an offense for bare sleep' do
      expect_offense(<<~RUBY)
        sleep
        ^^^^^ FussyPedant/RSpec/NoWait: Use Capybara's built-in waiting instead of `sleep`.
      RUBY
    end

    it 'registers an offense for sleep with argument' do
      expect_offense(<<~RUBY)
        sleep 2
        ^^^^^^^ FussyPedant/RSpec/NoWait: Use Capybara's built-in waiting instead of `sleep`.
      RUBY
    end

    it 'registers an offense for sleep with parenthesized argument' do
      expect_offense(<<~RUBY)
        sleep(0.5)
        ^^^^^^^^^^ FussyPedant/RSpec/NoWait: Use Capybara's built-in waiting instead of `sleep`.
      RUBY
    end
  end

  context 'with Kernel.sleep' do
    it 'registers an offense for Kernel.sleep' do
      expect_offense(<<~RUBY)
        Kernel.sleep 2
        ^^^^^^^^^^^^^^ FussyPedant/RSpec/NoWait: Use Capybara's built-in waiting instead of `sleep`.
      RUBY
    end

    it 'registers an offense for Kernel.sleep with parentheses' do
      expect_offense(<<~RUBY)
        Kernel.sleep(0.5)
        ^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/NoWait: Use Capybara's built-in waiting instead of `sleep`.
      RUBY
    end
  end

  context 'with using_wait_time' do
    it 'registers an offense for using_wait_time with block' do
      expect_offense(<<~RUBY)
        using_wait_time(10) do
        ^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/NoWait: Avoid overriding Capybara's wait time; rely on `default_max_wait_time`.
          expect(page).to have_content("hello")
        end
      RUBY
    end

    it 'registers an offense for using_wait_time without block' do
      expect_offense(<<~RUBY)
        using_wait_time(5)
        ^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/NoWait: Avoid overriding Capybara's wait time; rely on `default_max_wait_time`.
      RUBY
    end
  end

  context 'with wait: keyword argument' do
    it 'registers an offense for find with wait:' do
      expect_offense(<<~RUBY)
        find('.button', wait: 5)
                        ^^^^^^^ FussyPedant/RSpec/NoWait: Avoid explicit `wait:` option; rely on `default_max_wait_time`.
      RUBY
    end

    it 'registers an offense for has_css? with wait:' do
      expect_offense(<<~RUBY)
        page.has_css?('.button', wait: 10)
                                 ^^^^^^^^ FussyPedant/RSpec/NoWait: Avoid explicit `wait:` option; rely on `default_max_wait_time`.
      RUBY
    end

    it 'registers an offense for wait: 0' do
      expect_offense(<<~RUBY)
        find('.button', wait: 0)
                        ^^^^^^^ FussyPedant/RSpec/NoWait: Avoid explicit `wait:` option; rely on `default_max_wait_time`.
      RUBY
    end

    it 'registers an offense for wait: false' do
      expect_offense(<<~RUBY)
        find('.button', wait: false)
                        ^^^^^^^^^^^ FussyPedant/RSpec/NoWait: Avoid explicit `wait:` option; rely on `default_max_wait_time`.
      RUBY
    end
  end

  context 'when code does not use waits' do
    it 'does not register an offense for Capybara matchers' do
      expect_no_offenses(<<~RUBY)
        expect(page).to have_content("hello")
        expect(page).to have_css('.button')
      RUBY
    end

    it 'does not register an offense for default_max_wait_time assignment' do
      expect_no_offenses(<<~RUBY)
        Capybara.default_max_wait_time = 5
      RUBY
    end

    it 'does not register an offense for non-wait keyword arguments' do
      expect_no_offenses(<<~RUBY)
        find('.button', visible: true)
        find('.button', text: 'Click me')
      RUBY
    end

    it 'does not register an offense for wait in non-Capybara context' do
      expect_no_offenses(<<~RUBY)
        process.wait
        thread.join
      RUBY
    end
  end
end
