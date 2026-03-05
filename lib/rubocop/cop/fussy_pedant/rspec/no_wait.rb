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
          MSG_WAIT_TIME = "Avoid overriding Capybara's wait time; rely on `default_max_wait_time`."
          MSG_WAIT_OPTION = 'Avoid explicit `wait:` option; rely on `default_max_wait_time`.'

          RESTRICT_ON_SEND = %i[sleep using_wait_time].freeze

          # @!method sleep_call?(node)
          def_node_matcher :sleep_call?, <<~PATTERN
            {
              (send nil? :sleep ...)
              (send (const nil? :Kernel) :sleep ...)
            }
          PATTERN

          # @!method using_wait_time_call?(node)
          def_node_matcher :using_wait_time_call?, <<~PATTERN
            (send nil? :using_wait_time ...)
          PATTERN

          # @!method wait_option?(node)
          def_node_matcher :wait_option?, <<~PATTERN
            (pair (sym :wait) _)
          PATTERN

          def on_send(node)
            if sleep_call?(node)
              add_offense(node, message: MSG_SLEEP)
            elsif using_wait_time_call?(node)
              add_offense(node, message: MSG_WAIT_TIME)
            end
          end

          def on_pair(node)
            return unless wait_option?(node)

            add_offense(node, message: MSG_WAIT_OPTION)
          end
        end
      end
    end
  end
end
