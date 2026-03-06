# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Rails::ControllerMethodOrder, :config do
  let(:config) { RuboCop::Config.new }

  context 'when methods are in correct order' do
    it 'does not register an offense for REST actions in canonical order' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def show; end
          def new; end
          def create; end
          def edit; end
          def update; end
          def destroy; end
        end
      RUBY
    end

    it 'does not register an offense for partial REST actions in order' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def show; end
          def create; end
          def destroy; end
        end
      RUBY
    end

    it 'does not register an offense for REST then alphabetical public' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def show; end
          def archive; end
          def export; end
        end
      RUBY
    end

    it 'does not register an offense for correct full ordering' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def show; end
          def export; end

          protected

          def authorize_user; end
          def set_headers; end

          private

          def find_user; end
          def user_params; end
        end
      RUBY
    end

    it 'does not register an offense for only private methods alphabetized' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index; end

          private

          def authorize; end
          def find_user; end
          def user_params; end
        end
      RUBY
    end

    it 'does not register an offense for a single method' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
        end
      RUBY
    end

    it 'does not register an offense for non-controller classes' do
      expect_no_offenses(<<~RUBY)
        class UserService
          def destroy; end
          def create; end
        end
      RUBY
    end

    it 'does not register an offense for empty controllers' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
        end
      RUBY
    end

    it 'ignores non-method nodes (callbacks, constants, includes)' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          before_action :authenticate
          LIMIT = 25

          def index; end
          def show; end
        end
      RUBY
    end
  end

  context 'with REST action ordering violations' do
    it 'registers an offense when REST actions are out of order' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def create; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `create` (canonical REST order).
          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `create` to come before `index` (canonical REST order).
        end
      RUBY
    end

    it 'registers an offense when destroy comes before show' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def destroy; end
          ^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `show` to come before `destroy` (canonical REST order).
          def show; end
          ^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `destroy` to come before `show` (canonical REST order).
        end
      RUBY
    end

    it 'registers multiple offenses for multiple REST misordering' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def destroy; end
          ^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `destroy` (canonical REST order).
          def create; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `show` to come before `create` (canonical REST order).
          def show; end
          ^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `create` to come before `show` (canonical REST order).
          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `destroy` to come before `index` (canonical REST order).
        end
      RUBY
    end
  end

  context 'with alphabetical ordering violations' do
    it 'registers an offense for non-REST public methods out of order' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def export; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `archive` to come before `export` (alphabetical order within public methods).
          def archive; end
          ^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `export` to come before `archive` (alphabetical order within public methods).
        end
      RUBY
    end

    it 'registers an offense for private methods out of order' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def index; end

          private

          def user_params; end
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `find_user` to come before `user_params` (alphabetical order within private methods).
          def find_user; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `user_params` to come before `find_user` (alphabetical order within private methods).
        end
      RUBY
    end

    it 'registers an offense for protected methods out of order' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def index; end

          protected

          def set_headers; end
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `authorize_user` to come before `set_headers` (alphabetical order within protected methods).
          def authorize_user; end
          ^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `set_headers` to come before `authorize_user` (alphabetical order within protected methods).
        end
      RUBY
    end
  end

  context 'with section ordering violations' do
    it 'registers an offense when private method comes before public' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          private

          def find_user; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected public method `index` to come before private method `find_user`.
          def user_params; end
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `find_user` to come before `user_params` (alphabetical order within private methods).

          public

          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected private method `user_params` to come before public method `index`.
        end
      RUBY
    end

    it 'handles inline private def form' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def show; end

          private def find_user; end
          private def user_params; end
        end
      RUBY
    end

    it 'registers an offense for inline private def out of order' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def index; end

          private def user_params; end
                  ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `find_user` to come before `user_params` (alphabetical order within private methods).
          private def find_user; end
                  ^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `user_params` to come before `find_user` (alphabetical order within private methods).
        end
      RUBY
    end
  end

  context 'with autocorrect' do
    it 'reorders REST actions to canonical order' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def create; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `create` (canonical REST order).
          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `create` to come before `index` (canonical REST order).
        end
      RUBY

      expect_correction(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def create; end
        end
      RUBY
    end

    it 'reorders all sections correctly in a full controller' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def export; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `export` (alphabetical order within public methods).
          def create; end
          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `archive` to come before `index` (alphabetical order within public methods).
          def archive; end
          ^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `export` to come before `archive` (alphabetical order within public methods).

          protected

          def set_headers; end
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `authorize_user` to come before `set_headers` (alphabetical order within protected methods).
          def authorize_user; end
          ^^^^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `set_headers` to come before `authorize_user` (alphabetical order within protected methods).

          private

          def user_params; end
          ^^^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `find_user` to come before `user_params` (alphabetical order within private methods).
          def find_user; end
          ^^^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `user_params` to come before `find_user` (alphabetical order within private methods).
        end
      RUBY

      expect_correction(<<~RUBY)
        class UsersController < ApplicationController
          def index; end
          def create; end
          def archive; end
          def export; end

          protected

          def authorize_user; end
          def set_headers; end

          private

          def find_user; end
          def user_params; end
        end
      RUBY
    end

    it 'sorts private methods alphabetically' do
      expect_offense(<<~RUBY)
        class UsersController < ApplicationController
          def index; end

          private

          def zebra; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `alpha` to come before `zebra` (alphabetical order within private methods).
          def alpha; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `zebra` to come before `alpha` (alphabetical order within private methods).
        end
      RUBY

      expect_correction(<<~RUBY)
        class UsersController < ApplicationController
          def index; end

          private

          def alpha; end
          def zebra; end
        end
      RUBY
    end
  end

  context 'with edge cases' do
    it 'handles namespaced controller classes' do
      expect_offense(<<~RUBY)
        class Admin::UsersController < ApplicationController
          def create; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `create` (canonical REST order).
          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `create` to come before `index` (canonical REST order).
        end
      RUBY
    end

    it 'handles deeply nested controller classes' do
      expect_offense(<<~RUBY)
        module Admin
          class UsersController < ApplicationController
            def create; end
            ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `create` (canonical REST order).
            def index; end
            ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `create` to come before `index` (canonical REST order).
          end
        end
      RUBY
    end

    it 'handles controller with no REST actions' do
      expect_no_offenses(<<~RUBY)
        class DashboardController < ApplicationController
          def archive; end
          def export; end
          def search; end
        end
      RUBY
    end

    it 'registers an offense for non-REST only controller out of order' do
      expect_offense(<<~RUBY)
        class DashboardController < ApplicationController
          def search; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `archive` to come before `search` (alphabetical order within public methods).
          def archive; end
          ^^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `search` to come before `archive` (alphabetical order within public methods).
        end
      RUBY
    end

    it 'handles multi-line method bodies' do
      expect_no_offenses(<<~RUBY)
        class UsersController < ApplicationController
          def index
            @users = User.all
            respond_to do |format|
              format.html
              format.json { render json: @users }
            end
          end

          def show
            @user = User.find(params[:id])
          end
        end
      RUBY
    end

    it 'handles controllers inheriting from non-standard bases' do
      expect_offense(<<~RUBY)
        class ApiController < ActionController::API
          def create; end
          ^^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `index` to come before `create` (canonical REST order).
          def index; end
          ^^^^^^^^^^^^^^ FussyPedant/Rails/ControllerMethodOrder: Expected `create` to come before `index` (canonical REST order).
        end
      RUBY
    end
  end
end
