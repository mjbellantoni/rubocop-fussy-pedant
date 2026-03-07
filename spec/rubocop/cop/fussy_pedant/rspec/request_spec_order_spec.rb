# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::RSpec::RequestSpecOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when describes are in correct order' do
    it 'does not register an offense for REST actions in canonical order' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end
          describe 'GET /users/:id' do; end
          describe 'POST /users' do; end
          describe 'DELETE /users/:id' do; end
        end
      RUBY
    end

    it 'does not register an offense for full REST order' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end
          describe 'GET /users/:id' do; end
          describe 'GET /users/new' do; end
          describe 'POST /users' do; end
          describe 'GET /users/:id/edit' do; end
          describe 'PATCH /users/:id' do; end
          describe 'DELETE /users/:id' do; end
        end
      RUBY
    end

    it 'does not register an offense for REST then alphabetical non-REST' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end
          describe 'POST /users' do; end
          describe 'GET /users/export' do; end
          describe 'POST /users/import' do; end
        end
      RUBY
    end

    it 'does not register an offense for a single describe' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end
        end
      RUBY
    end

    it 'does not register an offense for PUT as update' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end
          describe 'PUT /users/:id' do; end
        end
      RUBY
    end
  end

  context 'when describes are out of order' do
    it 'registers an offense when REST actions are reversed' do
      expect_offense(<<~RUBY)
        RSpec.describe '/users' do
          describe 'DELETE /users/:id' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users` to come before `DELETE /users/:id`.
          describe 'GET /users' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `DELETE /users/:id` to come before `GET /users`.
        end
      RUBY
    end

    it 'registers an offense when POST comes before GET index' do
      expect_offense(<<~RUBY)
        RSpec.describe '/users' do
          describe 'POST /users' do; end
          ^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users` to come before `POST /users`.
          describe 'GET /users' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `POST /users` to come before `GET /users`.
        end
      RUBY
    end

    it 'registers an offense when non-REST comes before REST' do
      expect_offense(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users/export' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users` to come before `GET /users/export`.
          describe 'GET /users' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users/export` to come before `GET /users`.
        end
      RUBY
    end

    it 'registers an offense for non-REST out of alphabetical order' do
      expect_offense(<<~RUBY)
        RSpec.describe '/users' do
          describe 'POST /users/import' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users/export` to come before `POST /users/import`.
          describe 'GET /users/export' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `POST /users/import` to come before `GET /users/export`.
        end
      RUBY
    end
  end

  context 'with edge cases' do
    it 'does not register an offense for empty top-level describe' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
        end
      RUBY
    end

    it 'ignores non-describe child blocks (context, it, etc.)' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          let(:user) { create(:user) }

          describe 'GET /users' do; end
          describe 'POST /users' do; end
        end
      RUBY
    end

    it 'handles numeric id segments in paths' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end
          describe 'GET /users/1' do; end
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    it 'reorders REST actions to canonical order' do
      expect_offense(<<~RUBY)
        RSpec.describe '/users' do
          describe 'DELETE /users/:id' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users` to come before `DELETE /users/:id`.
          describe 'GET /users' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `DELETE /users/:id` to come before `GET /users`.
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end

          describe 'DELETE /users/:id' do; end
        end
      RUBY
    end

    it 'reorders REST then non-REST alphabetically' do
      expect_offense(<<~RUBY)
        RSpec.describe '/users' do
          describe 'POST /users/import' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users` to come before `POST /users/import`.
          describe 'DELETE /users/:id' do; end
          describe 'GET /users' do; end
          ^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `GET /users/export` to come before `GET /users`.
          describe 'GET /users/export' do; end
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/RSpec/RequestSpecOrder: Expected `POST /users/import` to come before `GET /users/export`.
        end
      RUBY

      expect_correction(<<~RUBY)
        RSpec.describe '/users' do
          describe 'GET /users' do; end

          describe 'DELETE /users/:id' do; end

          describe 'GET /users/export' do; end

          describe 'POST /users/import' do; end
        end
      RUBY
    end
  end
end
