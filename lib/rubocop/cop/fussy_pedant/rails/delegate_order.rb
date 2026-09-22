# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Declares one method per `delegate` and alphabetizes the
        # declarations by `to:` target, then by method name.
        #
        # A `delegate` naming several methods is split into one
        # declaration per method, each carrying every option of the
        # original.
        #
        # Ordering applies to a run: consecutive declarations with
        # nothing between them. A blank line, a comment line and any
        # other code all end the run, so deliberate groupings stay
        # put and each is sorted on its own. A declaration the cop
        # cannot order -- a splatted method list, a method that is
        # not a literal, a missing `to:` -- ends the run as well.
        #
        # Reordering rewrites whole lines, which would discard a
        # trailing comment, so a run holding one is reported but not
        # corrected. So is a run whose options span several lines,
        # since copying them onto each declaration would leave their
        # indentation adrift.
        #
        # @example
        #   # bad
        #   class Message
        #     delegate :draft_uuid, :context_type, to: :context
        #   end
        #
        #   # good
        #   class Message
        #     delegate :context_type, to: :context
        #     delegate :draft_uuid, to: :context
        #   end
        #
        #   # bad (sorted by method, not by target)
        #   class Message
        #     delegate :name, to: :user
        #     delegate :zip, to: :address
        #   end
        #
        #   # good
        #   class Message
        #     delegate :zip, to: :address
        #     delegate :name, to: :user
        #   end
        #
        #   # good (a blank line starts a new run)
        #   class Message
        #     delegate :handle, to: :user
        #     delegate :name, to: :user
        #
        #     delegate :city, to: :address
        #     delegate :zip, to: :address
        #   end
        class DelegateOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector
          include RangeHelp

          RESTRICT_ON_SEND = %i[delegate].freeze

          MSG_SPLIT = 'Declare one method per `delegate`.'

          MSG_ALPHABETICAL = 'Expected `:%<name>s` (to: `%<to>s`) to come ' \
                             'before `:%<other>s` (to: `%<other_to>s`) ' \
                             '(alphabetical by `to:`, then method).'

          def on_send(node)
            return unless delegation?(node)

            run = run_containing(node)
            return unless run.first.equal?(node)

            check_split(run)
            check_alphabetical(run)
          end

          private

          def run_containing(node)
            siblings = node.parent&.begin_type? ? node.parent.children : [node]

            runs(siblings).find { |run| run.any? { |member| member.equal?(node) } }
          end

          def runs(siblings)
            siblings.each_with_object([[]]) do |child, runs|
              unless delegation?(child)
                runs << []
                next
              end

              runs << [] if new_run?(runs.last, child)
              runs.last << child
            end
          end

          # Any line between two declarations ends the run, so blank
          # lines and comments both keep deliberate groupings apart.
          def new_run?(run, node)
            return false if run.empty?

            run.last.source_range.last_line + 1 < node.source_range.first_line
          end

          def delegation?(node)
            return false unless delegate_call?(node)
            return false unless target(node)

            literal_methods?(node)
          end

          def delegate_call?(node)
            node.is_a?(RuboCop::AST::SendNode) &&
              node.method?(:delegate) && node.receiver.nil? &&
              statement_start?(node)
          end

          def literal_methods?(node)
            methods = delegated_methods(node)

            methods.any? && methods.all? { |method| method.type?(:sym, :str) }
          end

          # Everything left of the call on its first line must be
          # blank, so rewriting whole lines discards nothing. This is
          # what keeps `private delegate :a, to: :b` out of a run.
          def statement_start?(node)
            range = node.source_range

            range.source_line[0...range.column].strip.empty?
          end

          def delegated_methods(node)
            options(node) ? node.arguments[0...-1] : node.arguments
          end

          def options(node)
            last = node.arguments.last

            last if last&.hash_type?
          end

          def target(node)
            pair = options(node)&.pairs&.find do |candidate|
              candidate.key.sym_type? && candidate.key.value == :to
            end

            pair&.value&.source
          end

          def check_split(run)
            run.each do |node|
              next unless delegated_methods(node).size > 1

              add_offense(node, message: MSG_SPLIT) do |corrector|
                rewrite(corrector, run)
              end
            end
          end

          def check_alphabetical(run)
            run.each_cons(2) do |previous, node|
              next if (sort_key(previous) <=> sort_key(node)) <= 0

              add_offense(node, message: alphabetical_message(previous, node)) do |corrector|
                rewrite(corrector, run)
              end
            end
          end

          # A declaration sorts where its first method lands once the
          # run is split, so a multi-method declaration is keyed by
          # its own alphabetically first method.
          def sort_key(node)
            declarations([node]).first.first
          end

          def alphabetical_message(previous, node)
            format(MSG_ALPHABETICAL,
                   name: sort_key(node).last,
                   to: sort_key(node).first,
                   other: sort_key(previous).last,
                   other_to: sort_key(previous).first)
          end

          def rewrite(corrector, run)
            return unless rewritable_run?(run)

            corrector.replace(run_range(run), corrected_run_source(run))
          end

          # Rewriting a run replaces whole lines, which would discard
          # a comment trailing one of them. A comment on its own line
          # cannot appear here: the gap it leaves ends the run.
          #
          # Options are copied verbatim onto every declaration they
          # came from, so options spread over several lines would be
          # copied with an indentation that no longer lines up. Such
          # a run is reported and left alone.
          def rewritable_run?(run)
            return false if run.any? { |node| options(node).multiline? }

            !processed_source.contains_comment?(run_range(run))
          end

          def corrected_run_source(run)
            indent = ' ' * run.first.source_range.column

            declarations(run).map { |_key, source| "#{indent}#{source}" }.join("\n")
          end

          # One `[[target, method], source]` pair per delegated
          # method, in the order the corrected run should read.
          def declarations(run)
            run.flat_map do |node|
              to = target(node)

              delegated_methods(node).map do |method|
                [[to, method.value.to_s],
                 "delegate #{method.source}, #{options(node).source}"]
              end
            end.sort_by(&:first)
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
