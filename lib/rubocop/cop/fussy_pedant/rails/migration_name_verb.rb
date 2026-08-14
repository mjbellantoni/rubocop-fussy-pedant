# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Requires ActiveRecord migration class names to start with a verb.
        #
        # @example
        #   # bad
        #   class KeyLeaseAgreementUniquenessOnTenancySpan < ActiveRecord::Migration[7.1]
        #   end
        #
        #   # good
        #   class AddKeyLeaseAgreementUniquenessOnTenancySpan < ActiveRecord::Migration[7.1]
        #   end
        class MigrationNameVerb < RuboCop::Cop::Base
          MSG = 'Migration class name should start with a verb ' \
                '(e.g. `Add`, `Remove`, `Create`).'

          def on_class(node)
            name_node = node.identifier
            first_word = name_node.short_name.to_s[/\A[A-Z][a-z]*/]
            return unless first_word
            return if verbs.include?(first_word)

            add_offense(name_node)
          end

          private

          def verbs
            @verbs ||= Array(cop_config['Verbs'])
          end
        end
      end
    end
  end
end
