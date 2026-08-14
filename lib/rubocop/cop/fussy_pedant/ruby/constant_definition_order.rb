# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Requires constant definitions within a class or module body to be
        # alphabetical within each contiguous run. A non-constant statement
        # breaks a run so ordering is never compared across other code.
        #
        # @example
        #   # bad
        #   class Foo
        #     XYLOPHONE = 1
        #     DINGUS = "foo"
        #   end
        #
        #   # good
        #   class Foo
        #     DINGUS = "foo"
        #     XYLOPHONE = 1
        #   end
        class ConstantDefinitionOrder < RuboCop::Cop::Base
          MSG = 'Alphabetize constant definitions; ' \
                '`%<name>s` should come before `%<other>s`.'

          def on_class(node)
            check_body(node.body)
          end
          alias on_module on_class

          private

          def check_body(body)
            return unless body

            each_run(body) { |run| check_run(run) }
          end

          def each_run(body)
            run = []
            statements_in(body).each do |stmt|
              if stmt.casgn_type?
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
