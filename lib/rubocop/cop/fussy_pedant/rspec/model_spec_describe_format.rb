# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module RSpec
        # In model specs, all direct-child describe blocks must use
        # `.method` or `#method` format.
        #
        # Encourages testing through methods rather than testing
        # framework declarations directly (validations, associations,
        # callbacks, etc.).
        #
        # @example
        #   # bad
        #   RSpec.describe User do
        #     describe 'validations' do
        #       it 'requires an email' do; end
        #     end
        #   end
        #
        #   # good
        #   RSpec.describe User do
        #     describe '#valid?' do
        #       it 'requires an email' do; end
        #     end
        #   end
        class ModelSpecDescribeFormat < RuboCop::Cop::Base
          MSG = 'Use `.method` or `#method` format for describe ' \
                'blocks in model specs, not `%<text>s`.'

          def on_block(node)
            return unless rspec_describe?(node)

            direct_child_blocks(node).each do |child|
              next unless child.send_node.method_name == :describe

              text = describe_text(child)
              next unless text
              next if method_format?(text)

              message = format(MSG, text: text)
              add_offense(child.send_node, message: message)
            end
          end
          alias on_numblock on_block

          private

          def direct_child_blocks(node)
            body = node.body
            return [] unless body

            if body.begin_type?
              body.each_child_node(:block, :numblock).to_a
            elsif body.block_type? || body.numblock_type?
              [body]
            else
              []
            end
          end

          def rspec_describe?(node)
            send_node = node.send_node
            send_node.receiver&.const_name == 'RSpec' &&
              send_node.method_name == :describe
          end

          def describe_text(node)
            first_arg = node.send_node.first_argument
            return nil unless first_arg&.str_type?

            first_arg.value
          end

          def method_format?(text)
            text.start_with?('.') || text.start_with?('#')
          end
        end
      end
    end
  end
end
