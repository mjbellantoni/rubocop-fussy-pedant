# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Requires a space just inside the delimiters of word and symbol
        # percent-array literals.
        #
        # @example
        #   # bad
        #   %w[foo bar]
        #
        #   # good
        #   %w[ foo bar ]
        class SpaceInsidePercentArray < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Put a space inside the delimiters of a percent array.'

          PERCENT_ARRAY = /\A%[wWiI]/

          def on_array(node)
            return unless percent_array?(node)
            return if node.children.empty?
            return if node.multiline?

            source = node.source
            open_index = source.index(/[\[({<]/)
            return unless open_index

            inner = source[(open_index + 1)...-1]
            return if inner.start_with?(' ') && inner.end_with?(' ')

            register_offense(node, source, open_index, inner)
          end

          private

          def register_offense(node, source, open_index, inner)
            add_offense(node) do |corrector|
              corrector.replace(node, corrected(source, open_index, inner))
            end
          end

          def percent_array?(node)
            node.source.match?(PERCENT_ARRAY)
          end

          def corrected(source, open_index, inner)
            prefix = source[0..open_index]
            closer = source[-1]
            # strip intentionally normalizes any interior leading/trailing
            # whitespace (tabs included) down to a single space on each side.
            "#{prefix} #{inner.strip} #{closer}"
          end
        end
      end
    end
  end
end
