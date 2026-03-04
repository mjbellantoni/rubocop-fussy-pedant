# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Enforces alphabetical ordering and one-value-per-line
        # formatting of ActiveRecord enum declarations.
        #
        # Only checks the new Rails 7+ syntax:
        # `enum :name, values`
        #
        # @example
        #   # bad
        #   enum :status, { draft: 0, published: 1, archived: 2 }
        #
        #   # good
        #   enum :status, {
        #     archived: 0,
        #     draft: 1,
        #     published: 2
        #   }
        #
        #   # bad
        #   enum :status, %i[draft published archived]
        #
        #   # good
        #   enum :status, %i[
        #     archived
        #     draft
        #     published
        #   ]
        class EnumOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          def on_send(node)
            return unless enum_new_syntax?(node)

            # TODO: implement
          end

          private

          def enum_new_syntax?(node)
            node.method?(:enum) &&
              node.receiver.nil? &&
              node.first_argument&.sym_type?
          end
        end
      end
    end
  end
end
