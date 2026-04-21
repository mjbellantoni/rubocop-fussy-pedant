# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags `when` and `else` clauses in `case` statements where the
        # body is on the same line as the keyword. The body should always
        # be on the next line.
        #
        # @example
        #   # bad
        #   case foo
        #   when 1 then :dingus
        #   when 2 then :freebus
        #   else :ding
        #   end
        #
        #   # good
        #   case foo
        #   when 1
        #     :dingus
        #   when 2
        #     :freebus
        #   else
        #     :ding
        #   end
        class NoSingleLineCaseBody < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG_WHEN = 'Move the body of `when` to the next line.'
          MSG_ELSE = 'Move the body of `else` to the next line.'

          def on_case(node)
            node.when_branches.each do |when_node|
              check_when(when_node)
            end
            check_else(node) if node.else_branch
          end

          private

          def check_when(when_node)
            body = when_node.body
            return unless body
            return unless when_node.source_range.line == body.source_range.line

            add_offense(when_node, message: MSG_WHEN) do |corrector|
              correct_when(corrector, when_node)
            end
          end

          def check_else(case_node)
            else_branch = case_node.else_branch
            else_keyword = case_node.loc.else
            return unless else_keyword.line == else_branch.source_range.line

            add_offense(case_node.loc.else.join(else_branch.source_range), message: MSG_ELSE) do |corrector|
              correct_else(corrector, case_node)
            end
          end

          def correct_when(corrector, when_node)
            indent = ' ' * when_node.source_range.column
            body = when_node.body
            buf = body.source_range.source_buffer

            keyword_end = when_node.conditions.last.source_range.end_pos
            range = Parser::Source::Range.new(buf, keyword_end, body.source_range.end_pos)
            corrector.replace(range, "\n#{indent}  #{body.source}")
          end

          def correct_else(corrector, case_node)
            indent = ' ' * case_node.loc.else.column
            else_branch = case_node.else_branch
            buf = else_branch.source_range.source_buffer

            range = Parser::Source::Range.new(buf, case_node.loc.else.end_pos, else_branch.source_range.end_pos)
            corrector.replace(range, "\n#{indent}  #{else_branch.source}")
          end
        end
      end
    end
  end
end
