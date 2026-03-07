# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module RSpec
        # Enforces ordering of describe blocks in model specs:
        # class methods (`.method`) first, then instance methods
        # (`#method`), each group in alphabetical order.
        #
        # Describe blocks that don't match `.method` or `#method`
        # format are ignored by this cop (see ModelSpecDescribeFormat).
        #
        # @example
        #   # bad
        #   RSpec.describe User do
        #     describe '#full_name' do; end
        #     describe '.search' do; end
        #   end
        #
        #   # good
        #   RSpec.describe User do
        #     describe '.search' do; end
        #     describe '#full_name' do; end
        #   end
        class ModelSpecMethodOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG_GROUP = 'Expected class method `%<expected>s` to come ' \
                      'before instance method `%<actual>s`.'

          MSG_ALPHABETICAL = 'Expected `%<expected>s` to come before ' \
                             '`%<actual>s` (alphabetical order).'

          def on_block(node)
            return unless rspec_describe?(node)

            describes = collect_method_describes(node)
            return if describes.size < 2

            check_ordering(describes)
          end
          alias on_numblock on_block

          private

          def rspec_describe?(node)
            send_node = node.send_node
            send_node.receiver&.const_name == 'RSpec' &&
              send_node.method_name == :describe
          end

          def collect_method_describes(node)
            return [] unless node.body

            node.body.each_child_node(:block, :numblock).filter_map do |child|
              next unless child.send_node.method_name == :describe

              build_describe_info(child)
            end
          end

          def build_describe_info(child)
            text = describe_text(child)
            return nil unless text

            type = method_type(text)
            return nil unless type

            { node: child, text: text, type: type,
              group_rank: type == :class_method ? 0 : 1,
              name: text[1..] }
          end

          def describe_text(node)
            first_arg = node.send_node.first_argument
            return nil unless first_arg&.str_type?

            first_arg.value
          end

          def method_type(text)
            return :class_method if text.start_with?('.')
            return :instance_method if text.start_with?('#')

            nil
          end

          def sort_key(describe_info)
            [describe_info[:group_rank], describe_info[:name]]
          end

          def check_ordering(describes)
            sorted = describes.sort_by { |d| sort_key(d) }

            describes.each_with_index do |desc, i|
              expected = sorted[i]
              next if desc[:text] == expected[:text]

              message = build_message(desc, expected)
              add_offense(desc[:node].send_node, message: message) do |corrector|
                autocorrect_describes(corrector, describes)
              end
            end
          end

          def build_message(actual, expected)
            if actual[:type] == :instance_method && expected[:type] == :class_method
              format(MSG_GROUP, expected: expected[:text], actual: actual[:text])
            else
              format(MSG_ALPHABETICAL, expected: expected[:text], actual: actual[:text])
            end
          end

          def autocorrect_describes(corrector, describes)
            sorted = describes.sort_by { |d| sort_key(d) }
            range = describe_range(describes)
            indent = ' ' * range.column
            corrector.replace(range, build_replacement(sorted, indent))
          end

          def describe_range(describes)
            first = describes.first[:node]
            last = describes.last[:node]
            first_range = include_leading_comment(first)
            first_range.join(last.source_range)
          end

          def include_leading_comment(node)
            comment = leading_comment(node)
            if comment
              comment.source_range.join(node.source_range)
            else
              node.source_range
            end
          end

          def leading_comment(node)
            comments = processed_source.ast_with_comments[node]
            return nil if comments.nil? || comments.empty?

            result = nil
            target_line = node.source_range.line - 1
            comments.reverse_each do |comment|
              break unless comment.source_range.line == target_line

              result = comment
              target_line -= 1
            end
            result
          end

          def build_replacement(sorted, indent)
            sorted.map.with_index do |desc, i|
              if i.zero?
                desc[:node].source
              else
                "\n#{indent}#{desc[:node].source}"
              end
            end.join("\n")
          end
        end
      end
    end
  end
end
