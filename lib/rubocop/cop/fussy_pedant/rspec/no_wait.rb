# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module RSpec
        # Flags explicit sleep and wait calls in test files.
        #
        # Capybara has built-in waiting that automatically retries
        # assertions. Explicit sleeps and wait overrides make tests
        # slow and flaky.
        #
        # @example
        #   # bad
        #   sleep 2
        #
        #   # bad
        #   Kernel.sleep(1)
        #
        #   # bad
        #   using_wait_time(10) do
        #     expect(page).to have_content("hello")
        #   end
        #
        #   # bad
        #   find('.button', wait: 5)
        #
        #   # good
        #   expect(page).to have_content("hello")
        #
        #   # good - configure default_max_wait_time in spec_helper instead
        #   Capybara.default_max_wait_time = 5
        class NoWait < RuboCop::Cop::Base
          MSG_SLEEP = "Use Capybara's built-in waiting instead of `sleep`."

          RESTRICT_ON_SEND = %i[sleep].freeze

          # @!method sleep_call?(node)
          def_node_matcher :sleep_call?, <<~PATTERN
            {
              (send nil? :sleep ...)
              (send (const nil? :Kernel) :sleep ...)
            }
          PATTERN

          def on_send(node)
            return unless sleep_call?(node)

            add_offense(node, message: MSG_SLEEP)
          end
        end
      end
    end
  end
end
