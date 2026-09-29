# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Flags ActiveRecord query construction at a call site. A query
        # built inline is a domain concept that was never named: the
        # reader gets `where(status: :pending)` where they could have
        # had `pending`. Give it a name -- a scope or class method on
        # the model, or a query object under `app/queries` -- and let
        # call sites speak that name instead.
        #
        # The rule is about vocabulary, not length. A chain of names you
        # defined is fine however long it runs; `Order.pending.overdue`
        # reads as domain language. A chain of ActiveRecord's generic
        # verbs outside the model is schema manipulation that leaked.
        #
        # Consumers that name nothing stay legal, so `Order.pending.first`,
        # `Order.pending.count` and `Foo.enabled.find(1)` all pass.
        # `pluck`, `pick` and `ids` are consumers but are forbidden
        # anyway: they hardcode a column at the call site, which is the
        # coupling this cop exists to remove.
        #
        # Scoping is `Exclude` in config/default.yml, covering
        # `app/models`, `app/queries` and `db`. Migrations and seeds do
        # raw relation work with no model to hang a scope on.
        #
        # Not autocorrected. The cop can neither invent the name nor
        # choose between a scope, a class method and a query object.
        #
        # Five entries -- `order`, `select`, `group`, `limit`, `offset`
        # -- offend only when called with arguments, because each
        # collides with a common non-ActiveRecord receiver. See
        # ARGUMENT_REQUIRED.
        #
        # @example
        #   # bad
        #   Order.where(status: :pending)
        #   Order.pending.order(created_at: :desc)
        #   user.orders.limit(5)
        #   Order.pending.pluck(:email)
        #
        #   # good
        #   Order.pending
        #   Order.pending.first
        #   Order.pending.count
        #   Foo.enabled.find(1)
        class NoInlineQuery < RuboCop::Cop::Base
          MSG = 'Name this query: add a scope to the model or a query ' \
                'object in app/queries. Call sites do not build queries.'

          # Relation builders, plus the three consumers that name a
          # column. Kept in step with config/default.yml by a spec.
          #
          # `merge`, `except`, `only`, `with`, `and`, `or`, `from`,
          # `lock` and `readonly` are deliberately absent despite living
          # in ActiveRecord's QUERYING_METHODS: each collides
          # catastrophically with a non-ActiveRecord receiver
          # (`Hash#merge`, `Hash#except`, `Data#with`, `Mutex#lock`) and
          # argument-presence does not rescue them, since `hash.merge(x)`
          # takes an argument too.
          DEFAULT_FORBIDDEN_METHODS = %w[
            where rewhere not
            joins left_joins left_outer_joins
            includes preload eager_load references
            order reorder reverse_order in_order_of
            limit offset
            group regroup having
            distinct select reselect
            unscope none strict_loading
            pluck pick ids
          ].to_set.freeze

          # Names that also read naturally on a non-ActiveRecord
          # receiver: `line_item.order` (the noun), `array.select { }`
          # (Enumerable), `config.limit` and `rect.offset` (readers).
          # ActiveRecord always passes arguments to these; the
          # collisions never do. A block is not an argument, so
          # `relation.select { }` is not an offense here -- it loads
          # every record, which is a performance smell, but it names no
          # column.
          #
          # Not configurable: this is a disambiguation detail, not a
          # policy knob.
          ARGUMENT_REQUIRED = %w[order select group limit offset].to_set.freeze

          def on_send(node)
            return unless forbidden?(node)
            return if chain_already_reported?(node)

            add_offense(node.loc.selector)
          end
          alias on_csend on_send

          private

          def forbidden?(node)
            name = node.method_name.to_s
            return false unless forbidden_methods.include?(name)
            return non_block_pass_arguments?(node) if ARGUMENT_REQUIRED.include?(name)

            true
          end

          # Block-pass arguments like `&:valid?` and `&block` do not count
          # as arguments for disambiguation purposes. This predicate returns
          # true only if the node has a literal argument (not a block-pass).
          def non_block_pass_arguments?(node)
            node.arguments.any? { |arg| arg.type != :block_pass }
          end

          # `Order.joins(:a).where(b).limit(5)` holds three forbidden
          # calls but is one defect. Report the innermost, where
          # construction begins, and skip any forbidden send whose
          # receiver chain already carries one.
          def chain_already_reported?(node)
            receiver = node.receiver

            while receiver&.type?(:send, :csend)
              return true if forbidden?(receiver)

              receiver = receiver.receiver
            end

            false
          end

          def forbidden_methods
            @forbidden_methods ||=
              Array(cop_config['ForbiddenMethods']).to_set(&:to_s)
          end
        end
      end
    end
  end
end
