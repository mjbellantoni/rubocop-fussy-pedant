# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags resolving a constant through a local variable, e.g. assigning a
        # namespace to a variable and scoping through it.
        #
        # @example
        #   # bad
        #   ns = Integrations::CorpusImport
        #   ns::FieldMapping.new
        #
        #   # good
        #   Integrations::CorpusImport::FieldMapping.new
        class NoNamespaceAssignment < RuboCop::Cop::Base
          MSG = 'Reference the namespace directly instead of resolving a ' \
                'constant through a local variable.'

          def on_const(node)
            scope = node.children.first
            return unless scope&.lvar_type?

            add_offense(node)
          end
        end
      end
    end
  end
end
