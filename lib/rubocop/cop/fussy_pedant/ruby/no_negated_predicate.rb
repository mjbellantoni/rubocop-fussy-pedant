# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags a predicate method call wrapped in `!` or `not`. A
        # negated predicate is a naming gap: the domain concept has a
        # name (`incomplete?`), and spelling it `!complete?` hides it.
        # Define the inverse predicate and call that instead.
        #
        # Predicates that take arguments or a block are never flagged,
        # because no inverse name can stand in for them (`!x.is_a?(Foo)`
        # has nothing to become). `AllowedMethods` exempts predicates
        # whose negation is idiomatic; it replaces the default list
        # rather than extending it.
        #
        # @example
        #   # bad
        #   !order.complete?
        #   not order.complete?
        #
        #   # good
        #   order.incomplete?
        #
        #   # good - takes an argument
        #   !user.authorized_for?(:admin)
        #
        #   # good - AllowedMethods
        #   !order.nil?
        class NoNegatedPredicate < RuboCop::Cop::Base
          MSG = 'Define an inverse predicate instead of negating ' \
                '`%<method>s`.'

          RESTRICT_ON_SEND = %i[!].freeze

          # Core and Rails predicates whose negation reads naturally, or
          # whose inverse RuboCop's own Style/InverseMethods already
          # suggests. Kept in step with config/default.yml by a spec.
          DEFAULT_ALLOWED_METHODS = %w[
            nil? empty? any? none? all? one? zero? positive? negative?
            even? odd? frozen? blank? present? persisted? new_record?
          ].to_set.freeze

          def on_send(node)
            predicate = node.receiver
            return unless bare_predicate?(predicate)
            return if allowed_methods.include?(predicate.method_name.to_s)

            add_offense(
              node,
              message: format(MSG, method: predicate.method_name)
            )
          end

          private

          # A predicate call with no arguments and no block. Anything
          # else -- a literal, a local variable, a parenthesized
          # expression, a block node -- is not a rename away from
          # reading positively.
          def bare_predicate?(node)
            return false unless node.respond_to?(:type)
            return false unless node.send_type? || node.csend_type?
            return false unless node.predicate_method?

            node.arguments.empty?
          end

          def allowed_methods
            @allowed_methods ||=
              if cop_config.key?('AllowedMethods')
                Array(cop_config['AllowedMethods']).to_set(&:to_s)
              else
                DEFAULT_ALLOWED_METHODS
              end
          end
        end
      end
    end
  end
end
