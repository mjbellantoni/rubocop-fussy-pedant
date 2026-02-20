# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module FactoryBot
        # Enforces that FactoryBot traits are defined in alphabetical order.
        #
        # Traits should be ordered alphabetically by their name to improve
        # readability and maintainability of factory definitions.
        #
        # @example
        #   # bad
        #   FactoryBot.define do
        #     factory :user do
        #       trait :with_posts do
        #         # ...
        #       end
        #
        #       trait :admin do
        #         # ...
        #       end
        #     end
        #   end
        #
        #   # good
        #   FactoryBot.define do
        #     factory :user do
        #       trait :admin do
        #         # ...
        #       end
        #
        #       trait :with_posts do
        #         # ...
        #       end
        #     end
        #   end
        class TraitsAlphabeticalOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Traits should be defined in alphabetical order. ' \
                'Expected `%<expected>s` to come before `%<current>s`.'

          def_node_matcher :factory_block?, <<~PATTERN
            (block
              (send nil? :factory ...)
              ...)
          PATTERN

          def_node_matcher :trait_block?, <<~PATTERN
            (block
              (send nil? :trait (sym $_))
              ...)
          PATTERN

          def on_block(node)
            return unless factory_block?(node)

            traits = collect_traits(node)
            return if traits.size < 2

            check_alphabetical_order(traits)
          end

          alias on_numblock on_block

          private

          def collect_traits(factory_node)
            traits = []

            factory_node.body&.each_child_node do |child|
              next unless child.block_type? || child.numblock_type?

              trait_name = trait_block?(child)
              next unless trait_name

              traits << { name: trait_name, node: child }
            end

            traits
          end

          def check_alphabetical_order(traits)
            traits.each_cons(2) do |previous_trait, current_trait|
              previous_name = previous_trait[:name].to_s
              current_name = current_trait[:name].to_s
              next if previous_name <= current_name

              register_offense(current_trait, previous_name, current_name, traits)
            end
          end

          def register_offense(current_trait, previous_name, current_name, traits)
            add_offense(
              current_trait[:node].send_node,
              message: format(MSG, expected: previous_name, current: current_name)
            ) do |corrector|
              autocorrect(corrector, traits)
            end
          end

          def autocorrect(corrector, traits)
            sorted_traits = traits.sort_by { |t| t[:name].to_s }

            traits.each_with_index do |trait, index|
              sorted_trait = sorted_traits[index]
              next if trait[:node] == sorted_trait[:node]

              corrector.replace(trait[:node], sorted_trait[:node].source)
            end
          end
        end
      end
    end
  end
end
