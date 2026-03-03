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

          def on_class(node)
            associations = collect_associations(node)
            return if associations.size < 2

            check_type_ordering(associations)
          end

          private

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
                          message: type_order_message(curr_assoc, prev_assoc))
            end
          end

          def type_order_message(curr_assoc, prev_assoc)
            format(MSG_TYPE_ORDER,
                   type: subtype_label(curr_assoc),
                   name: curr_assoc[:name],
                   prev_type: subtype_label(prev_assoc))
          end
        end
      end
    end
  end
end
