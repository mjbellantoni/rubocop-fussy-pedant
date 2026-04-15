# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags guard clause(s) immediately before the final expression
        # in a method or block body. These are disguised conditionals,
        # not true early returns. Use `if/else` or `case/when` instead.
        #
        # @example
        #   # bad
        #   def foo
        #     return [] if items.empty?
        #     items.sort
        #   end
        #
        #   # good
        #   def foo
        #     if items.empty?
        #       []
        #     else
        #       items.sort
        #     end
        #   end
        class NoTerminalGuardClause < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG_IF = 'Use `if/else` instead of a guard clause ' \
                   'before the final expression.'
          MSG_CASE = 'Use `case/when` instead of guard clauses ' \
                     'before the final expression.'

          def on_def(node)
            check_body(node.body)
          end
          alias on_defs on_def

          private

          def check_body(body)
            return unless body&.begin_type?

            statements = body.children
            return if statements.size < 2

            guards = terminal_guard_clauses(statements)
            return if guards.empty?

            register_offense(guards, statements.last)
          end

          def register_offense(guards, final_expr)
            message = guards.size == 1 ? MSG_IF : MSG_CASE
            add_offense(guards.first, message: message) do |corrector|
              correct_guard_clauses(corrector, guards, final_expr)
            end
          end

          def correct_guard_clauses(corrector, guards, final_expr)
            range = guards.first.source_range.join(
              final_expr.source_range
            )
            indent = ' ' * guards.first.source_range.column
            replacement = build_replacement(guards, final_expr, indent)
            corrector.replace(range, replacement)
          end

          def terminal_guard_clauses(statements)
            guards = []
            index = statements.size - 2
            while index >= 0 && guard_clause?(statements[index])
              guards.unshift(statements[index])
              index -= 1
            end
            guards
          end

          def guard_clause?(node)
            return false unless node.if_type?
            return false if node.else?
            return false unless node.modifier_form?

            node.if_branch&.return_type?
          end

          def build_replacement(guards, final_expr, indent)
            if guards.size == 1
              build_if_else(guards.first, final_expr, indent)
            else
              build_case_when(guards, final_expr, indent)
            end
          end

          def build_if_else(guard, final_expr, indent)
            if_val, else_val = if_else_branches(guard, final_expr, indent)
            "if #{guard.condition.source}\n" \
              "#{indent}  #{if_val}\n" \
              "#{indent}else\n" \
              "#{indent}  #{else_val}\n" \
              "#{indent}end"
          end

          def if_else_branches(guard, final_expr, indent)
            return_val = extract_return_value(guard)
            final_source = reindent_source(final_expr, indent)
            guard.unless? ? [final_source, return_val] : [return_val, final_source]
          end

          def build_case_when(guards, final_expr, indent)
            lines = +"case\n"
            guards.each do |guard|
              lines << "#{indent}when #{when_condition(guard)}\n"
              lines << "#{indent}  #{extract_return_value(guard)}\n"
            end
            lines << else_branch(final_expr, indent)
          end

          def when_condition(guard)
            guard.unless? ? "!#{guard.condition.source}" : guard.condition.source
          end

          def else_branch(final_expr, indent)
            final_source = reindent_source(final_expr, indent)
            "#{indent}else\n" \
              "#{indent}  #{final_source}\n" \
              "#{indent}end"
          end

          def extract_return_value(guard)
            value_node = guard.if_branch.children.first
            value_node ? value_node.source : 'nil'
          end

          def reindent_source(node, base_indent)
            lines = node.source.split("\n")
            return lines.first if lines.size == 1

            column = node.source_range.column
            tail = reindent_continuation(lines[1..], column, base_indent)
            [lines.first.lstrip, *tail].join("\n")
          end

          def reindent_continuation(lines, original_column, base_indent)
            lines.map do |line|
              relative = [line[/\A */].length - original_column, 0].max
              "#{base_indent}  #{' ' * relative}#{line.lstrip}"
            end
          end
        end
      end
    end
  end
end
