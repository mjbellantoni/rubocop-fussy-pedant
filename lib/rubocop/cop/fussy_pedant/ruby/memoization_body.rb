# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags a memoization whose value is a `begin` block, as in
        # `@foo ||= begin ... end`. The block is a chunk of code with a
        # coherent purpose, so name it: extract it into a method and
        # leave the reader doing one thing, caching. This is Fowler's
        # Extract Function (Extract Method in the first edition and in
        # Refactoring: Ruby Edition).
        #
        # Not autocorrected. Naming the extracted computation is the
        # refactoring; a cop that invents `compute_foo` produces
        # uniformly bland names and hides the one decision worth
        # making. Where the new method belongs -- below the reader, at
        # the end of the class, above or below an existing `private` --
        # is a judgement about the file that the cop cannot make either.
        #
        # A `begin` wrapping a single statement with no `rescue` is left
        # alone: core Style/RedundantBegin already reports it, and its
        # advice, deleting the `begin`, beats extracting a method.
        #
        # Despite the name, the cop matches instance variables only.
        # `@@cache ||=`, `$logger ||=` and a memoized local are all
        # accepted: the ivar reader is the idiom this rule is about.
        # Plain assignment is out of scope too, so `@config = begin ...
        # end` and `parsed = begin ... end` pass. The argument for
        # `||=` specifically is that caching and computing are two
        # jobs, which is not true of an assignment that only computes.
        #
        # These shapes also escape, and are reported by neither this
        # cop nor core:
        #
        #   @config ||= begin ... end.freeze   # kwbegin is a receiver
        #   @cache[key] ||= begin ... end      # not an ivar assignment
        #   self.thing ||= begin ... end       # not an ivar assignment
        #
        # Widening to any of them is a separate change, deliberately
        # not made here.
        #
        # @example
        #   # bad
        #   def structured_content
        #     @structured_content ||= begin
        #       parsed = message.parsed
        #       parsed.is_a?(Hash) ? parsed : {}
        #     rescue JSON::ParserError
        #       {}
        #     end
        #   end
        #
        #   # good
        #   def structured_content
        #     @structured_content ||= parsed_structured_content
        #   end
        #
        #   def parsed_structured_content
        #     parsed = message.parsed
        #     parsed.is_a?(Hash) ? parsed : {}
        #   rescue JSON::ParserError
        #     {}
        #   end
        #
        #   # good - core Style/RedundantBegin's territory, not ours
        #   def totals
        #     @totals ||= rows.sum(&:amount)
        #   end
        class MemoizationBody < RuboCop::Cop::Base
          MSG = 'Extract the body of the `%<name>s` memoization ' \
                'into a named method.'

          def on_or_asgn(node)
            body = node.rhs
            return unless node.lhs.ivasgn_type?
            return unless body.kwbegin_type?
            return if nothing_to_name?(body)
            return if core_reduces_it?(body)

            add_offense(
              body.loc.begin,
              message: format(MSG, name: node.name)
            )
          end

          private

          # An empty `begin` has no body to extract, so there is nothing
          # to name. No cop reports this shape: core's allowable_kwbegin?
          # short-circuits on empty_begin? too, so `@x ||= begin end`
          # goes unremarked by the pair of us. It is degenerate enough
          # not to be worth a rule of its own.
          def nothing_to_name?(node)
            node.children.empty?
          end

          # A `begin` around one plain statement reduces to
          # `@x ||= statement`, and core Style/RedundantBegin already
          # reports it. Deleting the `begin` beats extracting a method,
          # so that shape is core's and not ours.
          #
          # A rescue or ensure makes the kwbegin a single child of that
          # type however long the body, so those never reduce.
          def core_reduces_it?(node)
            node.children.one? &&
              !node.children.first.type?(:rescue, :ensure)
          end
        end
      end
    end
  end
end
