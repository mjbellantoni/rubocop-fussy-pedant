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

          MSG_ALPHABETICAL = 'Enum values should be in alphabetical order. ' \
                             'Expected `%<expected>s` before `%<current>s`.'

          def on_send(node)
            return unless enum_new_syntax?(node)

            values_node = node.arguments[1]
            return unless values_node

            check_alphabetical(values_node) if check_alphabetical?
          end

          private

          def check_alphabetical?
            cop_config.fetch('CheckAlphabetical', true)
          end

          def check_alphabetical(values_node)
            keys = extract_keys(values_node)
            return if keys.size < 2

            keys.each_cons(2) do |prev_key, curr_key|
              next if prev_key[:name].to_s <= curr_key[:name].to_s

              add_alphabetical_offense(prev_key, curr_key)
            end
          end

          def add_alphabetical_offense(prev_key, curr_key)
            add_offense(
              curr_key[:node],
              message: format(MSG_ALPHABETICAL,
                              expected: curr_key[:name],
                              current: prev_key[:name])
            )
          end

          def extract_keys(values_node)
            case values_node.type
            when :hash  then extract_hash_keys(values_node)
            when :array then extract_array_keys(values_node)
            else []
            end
          end

          def extract_hash_keys(hash_node)
            hash_node.pairs.map { |pair| { name: pair.key.value, node: pair } }
          end

          def extract_array_keys(array_node)
            array_node.values.map { |val| { name: val.value, node: val } }
          end

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
