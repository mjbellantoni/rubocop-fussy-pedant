# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Requires constant definitions within a class or module body to be
        # alphabetical within each contiguous run. A non-constant statement
        # breaks a run so ordering is never compared across other code.
        #
        # A constant that reads another constant from the same run also
        # breaks it, because that one has to be assigned first and no
        # ordering can change it.
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
        #
        #   # good (SEND_DELAY has to follow what it reads)
        #   class Foo
        #     UNDO_WINDOW = 30.seconds
        #     SEND_DELAY = UNDO_WINDOW + 1.second
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
              if continues_run?(stmt, run)
                run << stmt
              else
                yield run if run.size > 1
                run = stmt.casgn_type? ? [stmt] : []
              end
            end
            yield run if run.size > 1
          end

          def continues_run?(node, run)
            node.casgn_type? && !depends_on_run?(node, run)
          end

          # A constant whose value reads another constant from the same
          # run is evaluated after it, so that order is a load-time
          # dependency and not a style choice. The run ends there and a
          # new one starts, so ordering is never compared across the
          # dependency. A qualified reference matches on its last
          # segment, which can end a run that only looks dependent; that
          # costs an offense rather than reporting an impossible one.
          def depends_on_run?(node, run)
            return false if run.empty?

            defined_names = run.map(&:name)
            constants_read_by(node).any? { |name| defined_names.include?(name) }
          end

          def constants_read_by(node)
            value = node.expression
            return [] unless value

            value.each_node(:const).map(&:short_name)
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
