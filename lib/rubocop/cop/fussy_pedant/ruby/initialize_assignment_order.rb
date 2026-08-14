# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Requires instance variable assignments in `initialize` to be
        # alphabetical within each contiguous run. A non-assignment statement
        # breaks a run so ordering is never compared across other code.
        #
        # @example
        #   # bad
        #   def initialize
        #     @x = 1
        #     @bar = 2
        #   end
        #
        #   # good
        #   def initialize
        #     @bar = 2
        #     @x = 1
        #   end
        class InitializeAssignmentOrder < RuboCop::Cop::Base
          MSG = 'Alphabetize instance variable assignments in `initialize`; ' \
                '`%<name>s` should come before `%<other>s`.'

          def on_def(node)
            return unless node.method?(:initialize)
            return unless node.body

            each_run(node.body) { |run| check_run(run) }
          end

          private

          def each_run(body)
            run = []
            statements_in(body).each do |stmt|
              if stmt.ivasgn_type?
                run << stmt
              else
                yield run if run.size > 1
                run = []
              end
            end
            yield run if run.size > 1
          end

          def statements_in(body)
            body.begin_type? ? body.children : [body]
          end

          def check_run(run)
            # Compares each assignment against its immediate predecessor
            # (adjacent-pair strategy), so the message names the neighbor,
            # not the earliest violated position.
            run.each_cons(2) do |prev, curr|
              prev_name = prev.name.to_s
              curr_name = curr.name.to_s
              next if prev_name <= curr_name

              add_offense(curr, message: format(MSG, name: curr_name, other: prev_name))
            end
          end
        end
      end
    end
  end
end
