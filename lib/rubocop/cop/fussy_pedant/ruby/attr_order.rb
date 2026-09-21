# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Alphabetizes `attr_accessor`, `attr_reader`, `attr_writer`
        # and `attr` declarations.
        #
        # Ordering applies to a run: consecutive declarations of one
        # macro at one visibility, each naming a single attribute,
        # with nothing between them. A blank line, a comment line,
        # any other code, a change of macro or visibility, and a
        # declaration naming several attributes all end the run, so
        # deliberate groupings stay put and each is sorted on its own.
        #
        # This cop skips a declaration naming several attributes
        # rather than splitting it. Pair it with
        # `Style/AccessorGrouping` set to `EnforcedStyle: separated`,
        # which does the splitting, to get one attribute per line in
        # alphabetical order.
        #
        # Reordering rewrites whole lines, which would discard a
        # trailing comment, so a run holding one is reported but not
        # corrected.
        #
        # @example
        #   # bad
        #   class Form
        #     attr_accessor :retained_attachment_ids
        #     attr_accessor :existing_attachment_parts
        #   end
        #
        #   # good
        #   class Form
        #     attr_accessor :existing_attachment_parts
        #     attr_accessor :retained_attachment_ids
        #   end
        #
        #   # good (a blank line starts a new run)
        #   class Form
        #     attr_reader :name
        #     attr_reader :slug
        #
        #     attr_accessor :existing_attachment_parts
        #     attr_accessor :retained_attachment_ids
        #   end
        class AttrOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector
          include RangeHelp

          MACROS = %i[attr_accessor attr_reader attr_writer attr].freeze

          VISIBILITIES = %i[private protected public].freeze

          MSG = 'Expected `:%<name>s` to come before ' \
                '`:%<other>s` (alphabetical order).'

          def on_begin(node)
            accessor_runs(node).each do |run|
              next if run.size < 2

              check_alphabetical(run)
            end
          end

          private

          def accessor_runs(node)
            node.children.each_with_object([[]]) do |child, runs|
              unless accessor_declaration?(child)
                runs << []
                next
              end

              runs << [] if new_run?(runs.last, child)
              runs.last << child
            end
          end

          def new_run?(run, node)
            return false if run.empty?

            run_key(run.last) != run_key(node) ||
              lines_between?(run.last, node)
          end

          # A run holds one macro at one visibility, so `attr_reader`
          # and `private attr_reader` are never ordered against each
          # other and neither moves across the other.
          def run_key(node)
            [visibility(node), macro_call(node).method_name]
          end

          def lines_between?(previous, node)
            previous.source_range.last_line + 1 < node.source_range.first_line
          end

          def accessor_declaration?(node)
            !macro_call(node).nil?
          end

          # The macro send itself, reached through a visibility wrapper
          # when there is one, or nil when the node declares no single
          # named attribute.
          def macro_call(node)
            return nil unless node.is_a?(RuboCop::AST::SendNode)
            return nil unless node.receiver.nil?

            inner = visibility_wrapper?(node) ? node.first_argument : node
            inner if single_attribute_macro?(inner)
          end

          # A declaration naming several attributes is not one of
          # these, so it returns nil above and ends the run:
          # `Style/AccessorGrouping` is what splits those.
          def single_attribute_macro?(node)
            return false unless node.is_a?(RuboCop::AST::SendNode)
            return false unless MACROS.include?(node.method_name)
            return false unless node.receiver.nil? && node.arguments.one?

            node.first_argument.type?(:sym, :str)
          end

          def visibility(node)
            node.method_name if visibility_wrapper?(node)
          end

          def visibility_wrapper?(node)
            VISIBILITIES.include?(node.method_name) && node.arguments.one?
          end

          def check_alphabetical(run)
            run.each_cons(2) do |previous, node|
              next if attr_name(previous) <= attr_name(node)

              add_offense(node, message: message_for(previous, node)) do |corrector|
                next unless sortable_run?(run)

                corrector.replace(run_range(run), sorted_run_source(run))
              end
            end
          end

          # Rewriting a run replaces whole lines, which would discard a
          # comment trailing one of them. A comment on its own line
          # cannot appear here: the gap it leaves ends the run.
          def sortable_run?(run)
            !processed_source.contains_comment?(run_range(run))
          end

          def message_for(previous, node)
            format(MSG, name: attr_name(node), other: attr_name(previous))
          end

          def attr_name(node)
            macro_call(node).first_argument.value.to_s
          end

          def sorted_run_source(run)
            indent = ' ' * run.first.source_range.column
            sorted = run.sort_by { |node| attr_name(node) }

            sorted.map { |node| "#{indent}#{node.source}" }.join("\n")
          end

          def run_range(run)
            range_by_whole_lines(
              run.first.source_range.join(run.last.source_range)
            )
          end
        end
      end
    end
  end
end
