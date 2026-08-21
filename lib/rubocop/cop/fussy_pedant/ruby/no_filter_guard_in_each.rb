# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags `next` guards whose only job is filtering, when they
        # open an `each` block. Deciding *which* elements to act on
        # belongs on the receiver, not inside the block.
        #
        # Only guards that are side-effect free and depend on the
        # block parameter are flagged, since only those can move to
        # `select`/`reject` without changing behaviour.
        #
        # @example
        #   # bad
        #   RECIPIENT_FIELDS.each do |field|
        #     next unless permitted.key?(field)
        #     permitted[field] = normalize(permitted[field])
        #   end
        #
        #   # good
        #   RECIPIENT_FIELDS.select { |field| permitted.key?(field) }
        #                   .each do |field|
        #     permitted[field] = normalize(permitted[field])
        #   end
        #
        #   # bad - stacked guards filter just as much
        #   fields.each do |field|
        #     next unless field.ok?
        #     next if field.empty?
        #     process(field)
        #   end
        #
        #   # good
        #   fields.select(&:ok?).reject(&:empty?).each do |field|
        #     process(field)
        #   end
        #
        #   # good - the guard has a side effect, so it must stay
        #   fields.each do |field|
        #     next unless field.strip!
        #     process(field)
        #   end
        class NoFilterGuardInEach < RuboCop::Cop::Base
          MSG = 'Use %<methods>s on the receiver instead of %<guards>s.'

          ASSIGNMENT_TYPES = %i[
            lvasgn ivasgn cvasgn gvasgn casgn masgn
            op_asgn or_asgn and_asgn
          ].freeze

          ARGUMENT_TYPES = %i[arg optarg restarg].freeze

          MUTATING_METHODS = %i[<< push concat].freeze

          def on_block(node)
            check_each_block(node, block_arg_names(node.arguments))
          end

          def on_numblock(node)
            names = (1..node.children[1]).map { |index| :"_#{index}" }
            check_each_block(node, names)
          end

          def on_itblock(node)
            check_each_block(node, [:it])
          end

          private

          def check_each_block(node, param_names)
            return unless node.send_node.method?(:each)

            body = node.body
            return unless body&.begin_type?

            statements = body.children
            guards = leading_filter_guards(statements, param_names)
            return if guards.empty?
            return if guards.size == statements.size
            return if next_guard?(statements[guards.size])

            add_offense(guards.first, message: message_for(guards))
          end

          def leading_filter_guards(statements, param_names)
            guards = []
            statements.each do |statement|
              break unless filter_guard?(statement, param_names)

              guards << statement
            end
            guards
          end

          def message_for(guards)
            format(MSG, methods: methods_phrase(guards),
                        guards: guards_phrase(guards))
          end

          def methods_phrase(guards)
            return '`select`' if guards.all?(&:unless?)
            return '`reject`' if guards.none?(&:unless?)

            '`select`/`reject`'
          end

          def guards_phrase(guards)
            return 'these `next` filter guards' if guards.size > 1

            if guards.first.unless?
              'a `next unless` filter guard'
            else
              'a `next if` filter guard'
            end
          end

          def filter_guard?(node, param_names)
            return false unless next_guard?(node)

            references_param?(node.condition, param_names) &&
              !side_effect?(node.condition)
          end

          def next_guard?(node)
            return false unless node&.if_type?
            return false unless node.modifier_form?

            bare_next?(node.if_branch)
          end

          def bare_next?(branch)
            branch&.next_type? && branch.children.empty?
          end

          def references_param?(condition, param_names)
            return false if param_names.empty?

            condition.each_node(:lvar).any? do |lvar|
              param_names.include?(lvar.children.first)
            end
          end

          def block_arg_names(block_args)
            block_args.flat_map do |arg|
              arg.each_node(*ARGUMENT_TYPES).map { |a| a.children.first }
            end
          end

          def side_effect?(condition)
            condition.each_node(*ASSIGNMENT_TYPES).any? ||
              condition.each_node(:send).any? { |send| mutating?(send) }
          end

          def mutating?(send_node)
            send_node.method_name.to_s.end_with?('!') ||
              MUTATING_METHODS.include?(send_node.method_name)
          end
        end
      end
    end
  end
end
