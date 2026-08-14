# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Flags `attr_reader`/`attr_accessor`/`attr` declarations whose name
        # shadows a core `BasicObject`/`Kernel`/`Object` instance method. Such
        # an accessor silently replaces the built-in on every instance.
        #
        # @example
        #   # bad
        #   attr_reader :method
        #
        #   # good
        #   attr_reader :http_method
        class AttrShadowingBuiltin < RuboCop::Cop::Base
          MSG = '`%<name>s` shadows a built-in method; ' \
                'choose a non-colliding name.'

          READER_MACROS = %i[attr_reader attr_accessor attr].freeze

          BUILTIN_METHODS = (
            Object.instance_methods +
            Object.private_instance_methods +
            Kernel.instance_methods +
            Kernel.private_instance_methods +
            BasicObject.instance_methods
          ).uniq.map(&:to_s).grep(/\A[a-z_]\w*\z/).to_set.freeze

          def on_send(node)
            return unless node.receiver.nil?
            return unless READER_MACROS.include?(node.method_name)

            node.arguments.each do |arg|
              next unless arg.sym_type?

              name = arg.value.to_s
              next unless disallowed?(name)

              add_offense(arg, message: format(MSG, name: name))
            end
          end

          private

          def disallowed?(name)
            return false if allowed_names.include?(name)

            BUILTIN_METHODS.include?(name)
          end

          def allowed_names
            @allowed_names ||= Array(cop_config['AllowedNames']).to_set(&:to_s)
          end
        end
      end
    end
  end
end
