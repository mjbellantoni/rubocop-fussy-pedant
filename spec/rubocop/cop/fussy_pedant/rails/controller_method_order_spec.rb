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
end
