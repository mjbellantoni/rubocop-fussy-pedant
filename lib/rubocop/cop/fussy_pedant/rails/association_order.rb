# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Enforces consistent ordering and spacing of ActiveRecord
        # association declarations within model files.
        #
        # Associations must be ordered by subtype:
        # belongs_to, has_one, has_one :through, has_many,
        # has_many :through, has_and_belongs_to_many.
        #
        # Within each subtype, associations must be alphabetical.
        #
        # When a model has 3+ associations, blank lines are required
        # between different subtypes. With fewer than 3, no blank
        # lines should appear between associations.
        #
        # @example
        #   # bad
        #   class User < ApplicationRecord
        #     has_many :posts
        #     belongs_to :company
        #   end
        #
        #   # good
        #   class User < ApplicationRecord
        #     belongs_to :company
        #     has_many :posts
        #   end
        #
        #   # good (3+ associations with spacing)
        #   class User < ApplicationRecord
        #     belongs_to :company
        #
        #     has_many :comments
        #     has_many :posts
        #   end
        class AssociationOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          ASSOCIATION_METHODS = %i[
            belongs_to has_one has_many has_and_belongs_to_many
          ].freeze

          MSG_TYPE_ORDER = 'Expected `%<type>s :%<name>s` to come after ' \
                           '`%<prev_type>s` associations, not before.'

          MSG_ALPHABETICAL = 'Expected `%<name>s` to come before ' \
                             '`%<other>s` (alphabetical order ' \
                             'within %<type>s).'

          MSG_MISSING_BLANK_LINE = 'Add a blank line between ' \
                                   '`%<prev_type>s` and `%<next_type>s` ' \
                                   'associations.'
          MSG_EXTRA_BLANK_LINE = 'Remove blank line between associations ' \
                                 '(only %<count>s total).'

          def on_class(node)
            associations = collect_associations(node)
            return if associations.size < 2

            check_type_ordering(associations)
            check_alphabetical_ordering(associations) if check_alphabetical?
            check_spacing(associations) if check_spacing?
          end

          private

          def check_alphabetical?
            cop_config.fetch('CheckAlphabetical', true)
          end

          def check_spacing?
            cop_config.fetch('CheckSpacing', true)
          end

          def collect_associations(class_node)
            associations = []
            class_node.body&.each_child_node do |child|
              next unless child.send_type?
              next unless ASSOCIATION_METHODS.include?(child.method_name)

              associations << build_association(child)
            end
            associations
          end

          def build_association(node)
            {
              node: node,
              method_name: node.method_name,
              name: association_name(node),
              through: through_association?(node),
              rank: compute_rank(node)
            }
          end

          def association_name(node)
            node.first_argument.value
          end

          def through_association?(node)
            node.arguments.any? do |arg|
              next unless arg.hash_type?

              arg.pairs.any? { |pair| pair.key.value == :through }
            end
          end

          def compute_rank(node)
            through = through_association?(node)
            case node.method_name
            when :belongs_to then 0
            when :has_one then through ? 2 : 1
            when :has_many then through ? 4 : 3
            when :has_and_belongs_to_many then 5
            end
          end

          def subtype_label(association)
            method = association[:method_name]
            through = association[:through]
            case method
            when :belongs_to then 'belongs_to'
            when :has_one then through ? 'has_one :through' : 'has_one'
            when :has_many then through ? 'has_many :through' : 'has_many'
            when :has_and_belongs_to_many then 'has_and_belongs_to_many'
            end
          end

          def check_type_ordering(associations)
            associations.each_cons(2) do |prev_assoc, curr_assoc|
              next if curr_assoc[:rank] >= prev_assoc[:rank]

              add_offense(curr_assoc[:node],
                          message: type_order_message(curr_assoc, prev_assoc)) do |corrector|
                autocorrect_associations(corrector, associations)
              end
            end
          end

          def type_order_message(curr_assoc, prev_assoc)
            format(MSG_TYPE_ORDER,
                   type: subtype_label(curr_assoc),
                   name: curr_assoc[:name],
                   prev_type: subtype_label(prev_assoc))
          end

          def check_alphabetical_ordering(associations)
            associations.chunk { |a| a[:rank] }.each do |_rank, group|
              next if group.size < 2

              check_group_alphabetical(group, associations)
            end
          end

          def check_group_alphabetical(group, associations)
            group.each_cons(2) do |prev_assoc, curr_assoc|
              next if prev_assoc[:name].to_s <= curr_assoc[:name].to_s

              add_offense(
                curr_assoc[:node],
                message: alphabetical_message(curr_assoc, prev_assoc)
              ) do |corrector|
                autocorrect_associations(corrector, associations)
              end
            end
          end

          def alphabetical_message(curr_assoc, prev_assoc)
            format(MSG_ALPHABETICAL,
                   name: curr_assoc[:name],
                   other: prev_assoc[:name],
                   type: subtype_label(curr_assoc))
          end

          def check_spacing(associations)
            if associations.size < 3
              check_no_blank_lines(associations)
            else
              check_subtype_blank_lines(associations)
            end
          end

          def check_no_blank_lines(associations)
            associations.each_cons(2) do |prev_assoc, curr_assoc|
              next unless blank_line_between?(prev_assoc[:node], curr_assoc[:node])

              add_offense(
                curr_assoc[:node],
                message: format(MSG_EXTRA_BLANK_LINE, count: associations.size)
              ) do |corrector|
                autocorrect_associations(corrector, associations)
              end
            end
          end

          def check_subtype_blank_lines(associations)
            associations.each_cons(2) do |prev_assoc, curr_assoc|
              next if prev_assoc[:rank] == curr_assoc[:rank]
              next if blank_line_between?(prev_assoc[:node], curr_assoc[:node])

              add_offense(
                curr_assoc[:node],
                message: missing_blank_line_message(prev_assoc, curr_assoc)
              ) do |corrector|
                autocorrect_associations(corrector, associations)
              end
            end
          end

          def missing_blank_line_message(prev_assoc, curr_assoc)
            format(MSG_MISSING_BLANK_LINE,
                   prev_type: subtype_label(prev_assoc),
                   next_type: subtype_label(curr_assoc))
          end

          def autocorrect_associations(corrector, associations)
            sorted = associations.sort_by { |a| [a[:rank], a[:name].to_s] }
            range = association_range(associations)
            indent = ' ' * range.column
            corrector.replace(range, build_replacement(sorted, indent))
          end

          def association_range(associations)
            first_node = associations.first[:node]
            last_node = associations.last[:node]
            first_node.source_range.join(last_node.source_range)
          end

          def build_replacement(sorted_associations, indent)
            lines = []
            sorted_associations.each_with_index do |assoc, i|
              if i.positive? && sorted_associations.size >= 3 &&
                 assoc[:rank] != sorted_associations[i - 1][:rank]
                lines << ''
              end
              source = assoc[:node].source
              lines << (i.zero? ? source : "#{indent}#{source}")
            end
            lines.join("\n")
          end

          def blank_line_between?(node1, node2)
            lines = processed_source.lines
            after_first = node1.source_range.last_line
            before_second = node2.source_range.line - 2

            (after_first..before_second).any? do |index|
              lines[index].nil? || lines[index].strip.empty?
            end
          end
        end
      end
    end
  end
end
