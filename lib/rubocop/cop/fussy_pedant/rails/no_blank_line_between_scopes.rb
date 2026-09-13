# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Keeps consecutive `scope` declarations adjacent.
        #
        # Scopes read as one block of query definitions, so blank
        # lines between them are noise. A comment between two scopes
        # is deliberate grouping, so the blank line before it is
        # allowed.
        #
        # @example
        #   # bad
        #   class User < ApplicationRecord
        #     scope :active, -> { where(active: true) }
        #
        #     scope :recent, -> { order(created_at: :desc) }
        #   end
        #
        #   # good
        #   class User < ApplicationRecord
        #     scope :active, -> { where(active: true) }
        #     scope :recent, -> { order(created_at: :desc) }
        #   end
        #
        #   # good (a comment breaks the run)
        #   class User < ApplicationRecord
        #     scope :active, -> { where(active: true) }
        #
        #     # Only rows the sales team can see.
        #     scope :visible, -> { where(hidden: false) }
        #   end
        class NoBlankLineBetweenScopes < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector
          include RangeHelp

          MSG = 'Do not separate scope declarations with blank lines.'

          RESTRICT_ON_SEND = %i[scope].freeze

          def on_send(node)
            previous = previous_scope(node)
            return unless previous
            return unless only_blank_lines_between?(previous, node)

            add_offense(offense_range(node)) do |corrector|
              corrector.remove(blank_line_range(previous, node))
            end
          end

          private

          def previous_scope(node)
            return unless scope_declaration?(node)

            parent = node.parent
            return unless parent&.begin_type?

            sibling = node.left_sibling
            sibling if scope_declaration?(sibling)
          end

          def scope_declaration?(node)
            node.is_a?(RuboCop::AST::SendNode) &&
              node.method?(:scope) &&
              node.receiver.nil?
          end

          def only_blank_lines_between?(previous, node)
            lines = gap_lines(previous, node)

            lines.any? && lines.all? { |line| line.strip.empty? }
          end

          def gap_lines(previous, node)
            first, last = gap_line_numbers(previous, node)
            return [] if last < first

            (first..last).map { |number| processed_source.lines[number - 1] }
          end

          def gap_line_numbers(previous, node)
            [previous.source_range.last_line + 1,
             node.source_range.first_line - 1]
          end

          def blank_line_range(previous, node)
            first, last = gap_line_numbers(previous, node)
            buffer = processed_source.buffer
            gap = buffer.line_range(first).join(buffer.line_range(last))

            range_by_whole_lines(gap, include_final_newline: true)
          end

          def offense_range(node)
            selector = node.loc.selector
            argument = node.first_argument
            return selector unless argument
            return selector unless argument.source_range.line == selector.line

            selector.join(argument.source_range)
          end
        end
      end
    end
  end
end
