# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Alphabetizes `scope` declarations and keeps them adjacent.
        #
        # Both rules apply to a run: consecutive scope declarations
        # with no other code and no comment line between them. A
        # comment starts a new run, so deliberate groupings stay put
        # and each group is sorted on its own. Scopes whose name is
        # not a literal cannot be ordered, so they break the run.
        #
        # Reordering rewrites the whole run, which would discard a
        # trailing comment, so a run holding one is reported but not
        # corrected. A run split by blank lines is reordered only
        # once those lines are gone.
        #
        # @example
        #   # bad
        #   class User < ApplicationRecord
        #     scope :recent, -> { order(created_at: :desc) }
        #
        #     scope :active, -> { where(active: true) }
        #   end
        #
        #   # good
        #   class User < ApplicationRecord
        #     scope :active, -> { where(active: true) }
        #     scope :recent, -> { order(created_at: :desc) }
        #   end
        #
        #   # good (a comment starts a new run)
        #   class User < ApplicationRecord
        #     scope :active, -> { where(active: true) }
        #     scope :hidden, -> { where(hidden: true) }
        #
        #     # Time windows.
        #     scope :ancient, -> { order(created_at: :asc) }
        #     scope :recent, -> { order(created_at: :desc) }
        #   end
        class ScopeOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector
          include RangeHelp

          MSG_SPACING = 'Do not separate scope declarations with blank lines.'

          MSG_ALPHABETICAL = 'Expected `:%<name>s` to come before ' \
                             '`:%<other>s` (alphabetical order).'

          def on_begin(node)
            scope_runs(node).each do |run|
              next if run.size < 2

              check_spacing(run) if check_spacing?
              check_alphabetical(run) if check_alphabetical?
            end
          end

          private

          def check_alphabetical?
            cop_config.fetch('CheckAlphabetical', true)
          end

          def check_spacing?
            cop_config.fetch('CheckSpacing', true)
          end

          def scope_runs(node)
            node.children.each_with_object([[]]) do |child, runs|
              unless scope_declaration?(child)
                runs << []
                next
              end

              runs << [] if new_run?(runs.last, child)
              runs.last << child
            end
          end

          def new_run?(run, node)
            run.any? && comment_between?(run.last, node)
          end

          def scope_declaration?(node)
            return false unless node.is_a?(RuboCop::AST::SendNode)
            return false unless node.method?(:scope) && node.receiver.nil?

            name_node = node.first_argument
            name_node&.type?(:sym, :str)
          end

          def check_spacing(run)
            run.each_cons(2) do |previous, node|
              next unless blank_lines_between?(previous, node)

              add_offense(blank_line_start(previous, node), message: MSG_SPACING) do |corrector|
                corrector.remove(blank_line_range(previous, node))
              end
            end
          end

          def check_alphabetical(run)
            run.each_cons(2) do |previous, node|
              next if scope_name(previous) <= scope_name(node)

              add_offense(offense_range(node),
                          message: alphabetical_message(previous, node)) do |corrector|
                next unless sortable_run?(run)

                corrector.replace(run_range(run), sorted_run_source(run))
              end
            end
          end

          def alphabetical_message(previous, node)
            format(MSG_ALPHABETICAL,
                   name: scope_name(node),
                   other: scope_name(previous))
          end

          def scope_name(node)
            node.first_argument.value.to_s
          end

          # Rewriting a run drops anything sharing its lines, so a
          # trailing comment rules out correction. Blank lines are
          # removed by the spacing rule first, on an earlier pass.
          def sortable_run?(run)
            return false if run.each_cons(2).any? do |previous, node|
              blank_lines_between?(previous, node)
            end

            !processed_source.contains_comment?(run_range(run))
          end

          def sorted_run_source(run)
            indent = ' ' * run.first.source_range.column
            sorted = run.sort_by { |node| scope_name(node) }

            sorted.map { |node| "#{indent}#{node.source}" }.join("\n")
          end

          def run_range(run)
            range_by_whole_lines(
              run.first.source_range.join(run.last.source_range)
            )
          end

          def comment_between?(previous, node)
            gap_lines(previous, node).any? { |line| !line.strip.empty? }
          end

          def blank_lines_between?(previous, node)
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

          def blank_line_start(previous, node)
            first, = gap_line_numbers(previous, node)

            processed_source.buffer.line_range(first).begin
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
            return selector unless argument.source_range.line == selector.line

            selector.join(argument.source_range)
          end
        end
      end
    end
  end
end
