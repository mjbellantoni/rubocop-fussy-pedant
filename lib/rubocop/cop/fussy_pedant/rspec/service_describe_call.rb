# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module RSpec
        # Service specs should not nest a `describe '.call'` block.
        #
        # Services have a single public method (`.call`), so wrapping
        # examples in `describe '.call'` is redundant.
        #
        # @example
        #   # bad
        #   RSpec.describe MyService do
        #     describe '.call' do
        #       it 'does something' do; end
        #     end
        #   end
        #
        #   # good
        #   RSpec.describe MyService do
        #     it 'does something' do; end
        #   end
        class ServiceDescribeCall < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Remove redundant `describe \'%<method>s\'` — ' \
                'service specs test a single method.'

          def on_block(node)
            return unless rspec_describe?(node)

            body_children(node.body).each do |child|
              next unless child.block_type? && call_describe?(child)

              message = format(MSG, method: describe_text(child))
              add_offense(child.send_node, message: message) do |corrector|
                autocorrect(corrector, child, node)
              end
            end
          end
          alias on_numblock on_block

          private

          def body_children(body)
            return [] unless body

            body.begin_type? ? body.children : [body]
          end

          def rspec_describe?(node)
            send_node = node.send_node
            send_node.receiver&.const_name == 'RSpec' &&
              send_node.method_name == :describe
          end

          def call_describe?(node)
            send_node = node.send_node
            return false unless send_node.method_name == :describe

            text = describe_text(send_node)
            %w[.call #call].include?(text)
          end

          def describe_text(node)
            send_node = node.send_type? ? node : node.send_node
            first_arg = send_node.first_argument
            return nil unless first_arg&.str_type?

            first_arg.value
          end

          def autocorrect(corrector, describe_block, parent_block)
            range = range_with_surrounding(describe_block)
            body = describe_block.body
            return corrector.remove(range) unless body

            replacement = build_replacement(describe_block, parent_block)
            corrector.replace(range, "#{replacement}\n")
          end

          def build_replacement(describe_block, parent_block)
            target_indent = ' ' * (parent_block.send_node.source_range.column + 2)
            current_indent = ' ' * (describe_block.send_node.source_range.column + 2)

            reindent(body_source(describe_block), current_indent, target_indent)
          end

          def body_source(describe_block)
            body = describe_block.body
            source = describe_block.source_range.source_buffer.source
            body_start = body.source_range.begin_pos
            body_end = body.source_range.end_pos

            # Expand to include leading whitespace on the first line
            body_start -= 1 while body_start.positive? && source[body_start - 1] != "\n"

            source[body_start...body_end]
          end

          def reindent(source, current_indent, target_indent)
            lines = source.lines
            return '' if lines.empty?

            lines.map do |line|
              if line.strip.empty?
                "\n"
              else
                line.sub(/^#{Regexp.escape(current_indent)}/, target_indent)
              end
            end.join.rstrip
          end

          def range_with_surrounding(node)
            range = node.source_range
            source = range.source_buffer.source

            begin_pos = range.begin_pos
            begin_pos -= 1 while begin_pos.positive? && source[begin_pos - 1] != "\n"

            end_pos = range.end_pos
            end_pos += 1 while end_pos < source.length && source[end_pos] == "\n"

            Parser::Source::Range.new(range.source_buffer, begin_pos, end_pos)
          end
        end
      end
    end
  end
end
