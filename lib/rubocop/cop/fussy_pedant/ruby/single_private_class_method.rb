# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Requires a separate `private_class_method` directive for each method
        # rather than passing multiple names to a single directive.
        #
        # @example
        #   # bad
        #   private_class_method :foo, :bar
        #
        #   # good
        #   private_class_method :foo
        #   private_class_method :bar
        class SinglePrivateClassMethod < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Use a separate `private_class_method` directive for each method.'

          def on_send(node)
            return unless node.receiver.nil?
            return unless node.method?(:private_class_method)

            names = node.arguments
            return if names.size < 2
            return unless names.all? { |a| a.sym_type? || a.str_type? }

            add_offense(node) do |corrector|
              corrector.replace(node, replacement(node, names))
            end
          end

          private

          def replacement(node, names)
            indent = ' ' * node.source_range.column
            names.map.with_index do |arg, i|
              prefix = i.zero? ? '' : indent
              "#{prefix}private_class_method #{arg.source}"
            end.join("\n")
          end
        end
      end
    end
  end
end
