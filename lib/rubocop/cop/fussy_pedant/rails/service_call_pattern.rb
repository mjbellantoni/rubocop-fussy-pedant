# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Enforces service object pattern conventions:
        # 1. Must implement `def self.call(...)`
        # 2. Methods must be ordered: self.call, initialize, call, private
        # 3. No custom public class methods (only .call)
        # 4. Instance method must be named `call`
        # 5. Services should not be instantiated directly (use .call)
        #
        # @example
        #   # bad
        #   class MyService
        #     def self.perform(foo:)
        #       new(foo:).perform
        #     end
        #
        #     def initialize(foo:)
        #       @foo = foo
        #     end
        #
        #     def perform
        #       # ...
        #     end
        #   end
        #
        #   # good
        #   class MyService
        #     def self.call(...)
        #       new(...).call
        #     end
        #
        #     def initialize(foo:)
        #       @foo = foo
        #     end
        #
        #     def call
        #       # ...
        #     end
        #
        #     private
        #
        #     def helper_method
        #       # ...
        #     end
        #   end
        class ServiceCallPattern < RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
          MSG_MISSING_CALL = 'Service objects must implement `def self.call(...)`'
          MSG_WRONG_ORDER = 'Service methods must be ordered: self.call, initialize, call, private'
          MSG_CUSTOM_CLASS_METHOD = 'Service objects should only expose .call class method, found: %<method>s'
          MSG_WRONG_INSTANCE_METHOD = "Service instance method must be named 'call', found: %<method>s"
          MSG_DIRECT_INSTANTIATION = 'Services should be invoked via .call, not .new'

          def on_class(node) # rubocop:disable Metrics
            return unless in_services_directory?
            return if module_definition?(node)
            return if exception_class?(node)

            class_methods = collect_class_methods(node)
            instance_methods = collect_public_instance_methods(node)

            call_method = class_methods.find { |m| m.method_name == :call }
            unless call_method
              add_offense(node, message: MSG_MISSING_CALL)
              return
            end

            check_method_ordering(call_method, instance_methods)
            check_custom_class_methods(class_methods)
            check_instance_method_names(instance_methods)
          end

          def on_send(node)
            return unless node.method?(:new)
            return unless service_class?(node.receiver)
            return if in_spec_file?
            return if in_service_class_definition?(node)

            add_offense(node, message: MSG_DIRECT_INSTANTIATION)
          end

          private

          def check_custom_class_methods(class_methods)
            class_methods.each do |method|
              next if method.method_name == :call

              add_offense(
                method,
                message: format(MSG_CUSTOM_CLASS_METHOD, method: method.method_name)
              )
            end
          end

          def check_instance_method_names(instance_methods)
            instance_methods.each do |method|
              next if method.method_name == :call
              next if method.method_name == :initialize
              next if private_method?(method)

              add_offense(
                method,
                message: format(MSG_WRONG_INSTANCE_METHOD, method: method.method_name)
              )
            end
          end

          def collect_class_methods(class_node)
            class_node.each_descendant(:defs).select do |method_node|
              method_node.parent == class_node.body || method_node.parent == class_node
            end
          end

          def collect_public_instance_methods(class_node)
            methods = []
            in_private = false

            class_node.body&.each_child_node do |child|
              if child.send_type? && child.method?(:private) && child.arguments.empty?
                in_private = true
                next
              end

              methods << child if child.def_type? && !in_private
            end

            methods
          end

          def check_method_ordering(call_method, instance_methods) # rubocop:disable Metrics
            initialize_method = instance_methods.find { |m| m.method_name == :initialize }
            call_instance_method = instance_methods.find { |m| m.method_name == :call }

            methods_with_positions = build_method_positions(
              call_method, initialize_method, call_instance_method
            )

            sorted = methods_with_positions.sort_by { |_, _, pos| pos }
            expected_order = %i[class_call initialize instance_call]
            actual_order = sorted.map(&:first)

            expected_present = expected_order & actual_order
            actual_present = actual_order & expected_order

            return unless expected_present != actual_present

            violating = sorted.find { |name, _, _| expected_present.index(name) != actual_present.index(name) }
            add_offense(violating[1], message: MSG_WRONG_ORDER) if violating
          end

          def build_method_positions(call_method, init_method, call_instance)
            positions = [[:class_call, call_method, call_method.source_range.begin_pos]]
            positions << [:initialize, init_method, init_method.source_range.begin_pos] if init_method
            positions << [:instance_call, call_instance, call_instance.source_range.begin_pos] if call_instance
            positions
          end

          def exception_class?(node)
            return false unless node.parent_class

            parent_class = node.parent_class.source
            parent_class.include?('Error') || parent_class == 'StandardError'
          end

          def in_service_class_definition?(node)
            node.each_ancestor(:defs).any? { |ancestor| ancestor.method_name == :call }
          end

          def module_definition?(node)
            node.body&.module_type?
          end

          def private_method?(method_node) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
            class_node = method_node.ancestors.find(&:class_type?)
            return false unless class_node

            private_marker = nil
            class_node.body&.each_child_node do |child|
              private_marker = child if child.send_type? && child.method?(:private) && child.arguments.empty?
              if child == method_node
                return private_marker && private_marker.source_range.end_pos < method_node.source_range.begin_pos
              end
            end

            false
          end

          def service_class?(receiver_node)
            return false unless receiver_node&.const_type?
            return false unless services_directory

            class_name = receiver_node.source
            file_path = class_name
                        .gsub('::', '/')
                        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                        .downcase

            File.exist?(File.join(services_directory, "#{file_path}.rb"))
          end

          def services_directory
            dir = cop_config['ServicesDirectory']
            return if dir.nil? || dir.empty?

            File.join(config.base_dir_for_path_parameters, dir)
          end

          def in_services_directory?
            processed_source.file_path.include?('/app/services/')
          end

          def in_spec_file?
            processed_source.file_path.include?('/spec/')
          end
        end
      end
    end
  end
end
