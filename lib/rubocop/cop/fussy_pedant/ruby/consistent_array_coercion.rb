# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Enforces a single consistent idiom for coercing a possibly-nil value
        # to an array: either `Array(x)` or `(x || [])`, never a mix.
        #
        # @example EnforcedStyle: array_coercion (default)
        #   # bad
        #   (rows || [])
        #   # good
        #   Array(rows)
        #
        # @example EnforcedStyle: logical_or
        #   # bad
        #   Array(rows)
        #   # good
        #   (rows || [])
        class ConsistentArrayCoercion < RuboCop::Cop::Base
          include ConfigurableEnforcedStyle

          MSG_ARRAY = 'Use `Array(...)` to ensure an array, not `(... || [])`.'
          MSG_OR = 'Use `(... || [])` to ensure an array, not `Array(...)`.'

          # matches `x || []`
          def_node_matcher :or_empty_array?, <<~PATTERN
            (or _ (array))
          PATTERN

          # matches `Array(x)`
          def_node_matcher :array_coercion?, <<~PATTERN
            (send nil? :Array _)
          PATTERN

          def on_or(node)
            return unless style == :array_coercion
            return unless or_empty_array?(node)
            return unless node.rhs.children.empty?

            add_offense(offense_range(node), message: MSG_ARRAY)
          end

          def on_send(node)
            return unless style == :logical_or
            return unless array_coercion?(node)

            add_offense(node, message: MSG_OR)
          end

          private

          # Highlight the enclosing parentheses when the `or` is wrapped in
          # a `begin` node so the offense range matches `(x || [])`.
          def offense_range(node)
            parent = node.parent
            if parent&.begin_type? && parent.children.one? &&
               parent.source.start_with?('(')
              parent
            else
              node
            end
          end
        end
      end
    end
  end
end
