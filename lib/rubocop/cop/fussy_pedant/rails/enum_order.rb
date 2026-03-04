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
          MSG_ONE_PER_LINE = 'Each enum value should be on its own line.'

          def on_send(node)
            return unless enum_new_syntax?(node)

            values_node = node.arguments[1]
            return unless values_node

            check_alphabetical(values_node) if check_alphabetical?
            check_one_per_line(values_node) if check_one_per_line?
          end

          private

          def check_alphabetical?
            cop_config.fetch('CheckAlphabetical', true)
          end

          def check_one_per_line?
            cop_config.fetch('CheckOnePerLine', true)
          end

          def check_one_per_line(values_node)
            return if values_on_separate_lines?(values_node)

            add_offense(values_node, message: MSG_ONE_PER_LINE) do |corrector|
              autocorrect_enum(corrector, values_node)
            end
          end

          def values_on_separate_lines?(values_node)
            children = enum_children(values_node)
            return true if children.size < 2

            lines = children.map { |child| child.source_range.line }
            lines.uniq.size == lines.size
          end

          def enum_children(values_node)
            case values_node.type
            when :hash then values_node.pairs
            when :array then values_node.values
            else []
            end
          end

          def check_alphabetical(values_node)
            keys = extract_keys(values_node)
            return if keys.size < 2

            keys.each_cons(2) do |prev_key, curr_key|
              next if prev_key[:name].to_s <= curr_key[:name].to_s

              add_alphabetical_offense(prev_key, curr_key, values_node)
            end
          end

          def add_alphabetical_offense(prev_key, curr_key, values_node)
            add_offense(
              curr_key[:node],
              message: format(MSG_ALPHABETICAL,
                              expected: curr_key[:name],
                              current: prev_key[:name])
            ) do |corrector|
              autocorrect_enum(corrector, values_node)
            end
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

          def autocorrect_enum(corrector, values_node)
            indent = ' ' * values_node.parent.source_range.column
            value_indent = "#{indent}  "
            replacement = build_enum_replacement(values_node, indent, value_indent)
            corrector.replace(values_node, replacement)
          end

          def build_enum_replacement(values_node, indent, value_indent)
            case values_node.type
            when :hash
              build_hash_replacement(values_node, indent, value_indent)
            when :array
              build_array_replacement(values_node, indent, value_indent)
            end
          end

          def build_hash_replacement(values_node, indent, value_indent)
            sorted_pairs = values_node.pairs.sort_by { |pair| pair.key.value.to_s }
            lines = sorted_pairs.map { |pair| "#{value_indent}#{pair.source}" }
            lines.last.sub!(/,\s*\z/, '')
            lines[0...-1].each { |line| line << ',' unless line.end_with?(',') }
            "{\n#{lines.join("\n")}\n#{indent}}"
          end

          def build_array_replacement(values_node, indent, value_indent)
            sorted_values = values_node.values.sort_by { |val| val.value.to_s }

            if percent_literal?(values_node)
              build_percent_replacement(values_node, sorted_values, indent, value_indent)
            else
              build_bracket_array_replacement(sorted_values, indent, value_indent)
            end
          end

          def build_percent_replacement(values_node, sorted_values, indent, value_indent)
            opener = values_node.source[/\A%[iIwW]\[/]
            lines = sorted_values.map { |val| "#{value_indent}#{val.value}" }
            "#{opener}\n#{lines.join("\n")}\n#{indent}]"
          end

          def build_bracket_array_replacement(sorted_values, indent, value_indent)
            lines = sorted_values.map { |val| "#{value_indent}#{val.source}" }
            lines.last.sub!(/,\s*\z/, '')
            lines[0...-1].each { |line| line << ',' unless line.end_with?(',') }
            "[\n#{lines.join("\n")}\n#{indent}]"
          end

          def percent_literal?(node)
            node.source.start_with?('%')
          end
        end
      end
    end
  end
end
