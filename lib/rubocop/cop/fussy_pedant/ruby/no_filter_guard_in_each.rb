# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags a `next` guard whose only job is filtering, when it
        # opens an `each` block. Deciding *which* elements to act on
        # belongs on the receiver, not inside the block.
        #
        # Only a guard that is side-effect free and depends on the
        # block parameter is flagged, since only those can move to
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
        #   # good - the guard has a side effect, so it must stay
        #   fields.each do |field|
        #     next unless field.strip!
        #     process(field)
        #   end
        class NoFilterGuardInEach < RuboCop::Cop::Base
          MSG_SELECT = 'Use `select` on the receiver instead of a ' \
                       '`next unless` filter guard.'
          MSG_REJECT = 'Use `reject` on the receiver instead of a ' \
                       '`next if` filter guard.'

          ASSIGNMENT_TYPES = %i[
            lvasgn ivasgn cvasgn gvasgn casgn masgn
            op_asgn or_asgn and_asgn
          ].freeze

          ARGUMENT_TYPES = %i[arg optarg restarg].freeze

          MUTATING_METHODS = %i[<< push concat].freeze

          def on_block(node)
            return unless node.send_node.method?(:each)

            body = node.body
            return unless body&.begin_type?

            statements = body.children
            guard = statements.first
            return unless filter_guard?(guard, node.arguments)
            return if next_guard?(statements[1])

            add_offense(guard, message: message_for(guard))
          end

          private

          def message_for(guard)
            guard.unless? ? MSG_SELECT : MSG_REJECT
          end

          def filter_guard?(node, block_args)
            return false unless next_guard?(node)

            references_block_param?(node.condition, block_args) &&
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

          def references_block_param?(condition, block_args)
            names = block_arg_names(block_args)
            return false if names.empty?

            condition.each_node(:lvar).any? do |lvar|
              names.include?(lvar.children.first)
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
