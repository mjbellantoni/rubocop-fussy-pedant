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
        # `Order.pending.count` and `Foo.enabled.find(1)` all pass. So do
        # `pluck`, `pick` and `ids`: see DEFAULT_FORBIDDEN_METHODS for
        # why the "hardcodes a column" argument against them does not
        # survive.
        #
        # Scoping is native `Include`/`Exclude` in config/default.yml.
        # `Include` keeps the cop to `app/` and `lib/`, off `Gemfile`,
        # `Rakefile`, `config/` and `bin/`, where these names are
        # certainly not ActiveRecord. `Exclude` then drops `app/models`
        # (the naming layer itself), `app/queries` (the designated home
        # for complex one-offs), `app/policies` (a Pundit `Scope#resolve`
        # is a query object in everything but name), `app/helpers` and
        # `app/components` (where ActionView's form builder lives, and
        # `f.select(:status, opts)` is indistinguishable from
        # `Order.select(:id, :status)`), and `db` (migrations and seeds
        # do raw relation work with no model to hang a scope on).
        #
        # The leading `**/` on both keys is load-bearing. Without it on
        # `Exclude` an engine's models go unscoped; without it on
        # `Include` an engine's `app/` and `lib/` fall outside the cop
        # entirely and it goes silent across every engine in the app.
        #
        # Consumers adding a directory need `inherit_mode: merge`; both
        # keys replace rather than merge.
        #
        # `Order.joins(:a).where(b).limit(5)` holds three forbidden calls
        # but is one defect, so the cop reports once, on the innermost
        # forbidden call, where construction begins. The walk descends
        # through block nodes: `Order.where(a).map { }.select(:id)` is
        # still one chain and still one offense.
        #
        # Not autocorrected. The cop can neither invent the name nor
        # choose between a scope, a class method and a query object.
        #
        # Six entries -- `order`, `select`, `group`, `limit`, `offset`
        # and `references` -- offend only when called with arguments,
        # because each collides with a common non-ActiveRecord receiver.
        # See ARGUMENT_REQUIRED.
        #
        # @example
        #   # bad
        #   Order.where(status: :pending)
        #   Order.pending.order(created_at: :desc)
        #   Order.pending.distinct
        #   user.orders.limit(5)
        #
        #   # good
        #   Order.pending
        #   Order.pending.first
        #   Order.pending.count
        #   Foo.enabled.find(1)
        class NoInlineQuery < RuboCop::Cop::Base
          MSG = 'Name this query: add a scope to the model or a query ' \
                'object in app/queries. Call sites do not build queries.'

          # Relation builders. Every entry constructs a relation; nothing
          # else qualifies. Kept in step with config/default.yml by a
          # spec, and used as the fallback when a consumer configures the
          # cop without naming a list.
          #
          # `merge`, `except`, `only`, `with`, `and`, `or`, `from`,
          # `lock` and `readonly` are deliberately absent despite living
          # in ActiveRecord's QUERYING_METHODS: each collides
          # catastrophically with a non-ActiveRecord receiver
          # (`Hash#merge`, `Hash#except`, `Data#with`, `Mutex#lock`) and
          # argument-presence does not rescue them, since `hash.merge(x)`
          # takes an argument too.
          #
          # `pluck`, `pick` and `ids` are absent as well. An earlier
          # draft included them because they hardcode a column at the
          # call site, but that rationale equally indicts `find_by(email:)`,
          # `exists?`, `sum(:total)` and `count(:email)`, which this cop
          # blesses. It also caused two concrete problems: `Rails/SelectMap`
          # autocorrects `Order.select(:email).map(&:email)` into
          # `Order.pluck(:email)` and both states offended, so `rubocop -a`
          # moved code between two offenses with no fixed point; and the
          # cheapest legal rewrite of `pluck(:x)` is `map(&:x)`, which
          # loads every record. A cop whose cheapest escape is a
          # performance regression teaches the wrong lesson.
          #
          # `not` is absent because it cannot produce a true positive.
          # `WhereChain#not` is reachable only through `where`, and
          # `where` is the innermost forbidden call, so chain
          # deduplication always reports `where` first. Every offense
          # `not` would emit is therefore a false one (`validator.not(rule)`).
          #
          # `none`, `reorder` and `excluding` are absent as un-gateable
          # collisions. `policy_scope.none` is the canonical Pundit
          # empty-relation return and `list.reorder(params[:ids])` is
          # ordinary collection code; both have the same arity as their
          # ActiveRecord namesakes. `excluding` is also an ActiveSupport
          # `Enumerable` method (aliased `without`), so
          # `records.excluding(current_user)` on a plain Array collides,
          # and it always takes an argument -- the same shape argument
          # presence cannot separate. For all three, an allowlist escape
          # would remove the true positives too, since the name is
          # identical. Including any of them ships a known false
          # positive, which this set does not do.
          DEFAULT_FORBIDDEN_METHODS = %w[
            where rewhere
            joins left_joins left_outer_joins
            includes preload eager_load references
            order reverse_order in_order_of
            limit offset
            group regroup having
            distinct select reselect
            unscope unscoped strict_loading
          ].to_set.freeze

          # Names that also read naturally on a non-ActiveRecord
          # receiver: `line_item.order` (the noun), `array.select { }`
          # (Enumerable), `config.limit` and `rect.offset` (readers), and
          # `candidate.references` (a `has_many`). ActiveRecord always
          # passes arguments to these; the collisions never do.
          #
          # Neither a literal block nor a block-pass counts as an
          # argument, so `relation.select { }` and `items.select(&:valid?)`
          # are not offenses here -- they load every record, which is a
          # performance smell, but they name no column.
          #
          # Not configurable: this is a disambiguation detail, not a
          # policy knob.
          ARGUMENT_REQUIRED = %w[order select group limit offset references].to_set.freeze

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

            while receiver
              return true if receiver.type?(:send, :csend) && forbidden?(receiver)

              receiver = chained_receiver(receiver)
            end

            false
          end

          # A block interrupts the send chain: the AST for
          # `Order.where(a).map { }.select(:id)` puts a block node
          # between the two sends. Descend through it to the send it
          # wraps so the walk still reaches the construction underneath.
          # `map { _1 }` and `map { it }` are `numblock` and `itblock`,
          # not `block`, so all three have to be named.
          def chained_receiver(node)
            case node.type
            when :send, :csend then node.receiver
            when :block, :numblock, :itblock then node.send_node
            end
          end

          def forbidden_methods
            @forbidden_methods ||= configured_forbidden_methods
          end

          # An absent or empty `ForbiddenMethods` means a consumer wrote
          # a partial config (`Enabled: true` alone); it must not silence
          # the cop.
          def configured_forbidden_methods
            configured = Array(cop_config['ForbiddenMethods']).to_set(&:to_s)
            configured.empty? ? DEFAULT_FORBIDDEN_METHODS : configured
          end
        end
      end
    end
  end
end
