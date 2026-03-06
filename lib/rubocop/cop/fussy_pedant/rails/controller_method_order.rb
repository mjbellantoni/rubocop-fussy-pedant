# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Enforces consistent method ordering in Rails controllers.
        #
        # Public methods: REST actions first in canonical order
        # (index, show, new, create, edit, update, destroy),
        # then non-REST public methods alphabetized.
        # Protected methods: alphabetized.
        # Private methods: alphabetized.
        #
        # @example
        #   # bad
        #   class UsersController < ApplicationController
        #     def create; end
        #     def index; end
        #   end
        #
        #   # good
        #   class UsersController < ApplicationController
        #     def index; end
        #     def create; end
        #   end
        class ControllerMethodOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          DEFAULT_REST_ACTIONS = %i[
            index show new create edit update destroy
          ].freeze

          MSG_REST_ORDER = 'Expected `%<method>s` to come before ' \
                           '`%<other>s` (canonical REST order).'

          MSG_ALPHABETICAL = 'Expected `%<method>s` to come before ' \
                             '`%<other>s` (alphabetical order within ' \
                             '%<visibility>s methods).'

          MSG_SECTION_ORDER = 'Expected %<visibility>s method `%<method>s` ' \
                              'to come before %<other_visibility>s method ' \
                              '`%<other>s`.'

          def on_class(node)
            return unless controller_class?(node)

            methods = collect_methods(node)
            return if methods.size < 2

            check_ordering(methods)
          end

          private

          def controller_class?(node)
            class_name = node.identifier.short_name.to_s
            class_name.end_with?('Controller')
          end

          def rest_actions
            @rest_actions ||= (cop_config['RestActions'] || DEFAULT_REST_ACTIONS).map(&:to_sym)
          end

          def collect_methods(class_node)
            methods = []
            visibility = :public

            class_node.body&.each_child_node do |child|
              case child.type
              when :send
                new_vis = visibility_from_send(child)
                if new_vis
                  if child.arguments.empty?
                    visibility = new_vis
                  else
                    # inline form: private def foo
                    inner_def = child.first_argument
                    if inner_def&.def_type?
                      methods << build_method(inner_def, new_vis, child)
                    end
                  end
                end
              when :def
                methods << build_method(child, visibility, child)
              end
            end

            methods
          end

          def visibility_from_send(node)
            case node.method_name
            when :public then :public
            when :protected then :protected
            when :private then :private
            end
          end

          def build_method(def_node, visibility, outer_node)
            name = def_node.method_name
            rest_index = rest_actions.index(name)
            {
              name: name,
              visibility: visibility,
              rest_action: !rest_index.nil?,
              rest_rank: rest_index || Float::INFINITY,
              node: outer_node,
              def_node: def_node
            }
          end

          def sort_key(method_info)
            vis_rank = case method_info[:visibility]
                       when :public then 0
                       when :protected then 1
                       when :private then 2
                       end

            if method_info[:visibility] == :public && method_info[:rest_action]
              [vis_rank, 0, method_info[:rest_rank], '']
            elsif method_info[:visibility] == :public
              [vis_rank, 1, 0, method_info[:name].to_s]
            else
              [vis_rank, 0, 0, method_info[:name].to_s]
            end
          end

          def check_ordering(methods)
            sorted = methods.sort_by { |m| sort_key(m) }

            methods.each_with_index do |method_info, i|
              expected = sorted[i]
              next if method_info[:name] == expected[:name]

              message = build_message(method_info, methods, sorted, i)
              add_offense(method_info[:def_node], message: message) do |corrector|
                autocorrect_methods(corrector, methods)
              end
            end
          end

          def build_message(method_info, methods, sorted, index)
            expected = sorted[index]

            if method_info[:visibility] != expected[:visibility]
              # Section ordering violation - find what should be here
              format(MSG_SECTION_ORDER,
                     visibility: expected[:visibility],
                     method: expected[:name],
                     other_visibility: method_info[:visibility],
                     other: method_info[:name])
            elsif method_info[:rest_action] && expected[:rest_action]
              format(MSG_REST_ORDER,
                     method: expected[:name],
                     other: method_info[:name])
            else
              format(MSG_ALPHABETICAL,
                     method: expected[:name],
                     other: method_info[:name],
                     visibility: method_info[:visibility])
            end
          end

          def autocorrect_methods(corrector, methods)
            sorted = methods.sort_by { |m| sort_key(m) }
            range = method_range(methods)
            indent = ' ' * range.column
            corrector.replace(range, build_replacement(sorted, indent, methods))
          end

          def method_range(methods)
            first = methods.first[:node]
            last = methods.last[:node]
            first_range = first_line_range(first)
            first_range.join(last.source_range)
          end

          def first_line_range(node)
            # Include leading comments
            comment = leading_comment(node)
            if comment
              comment.source_range.join(node.source_range)
            else
              node.source_range
            end
          end

          def leading_comment(node)
            comments = processed_source.ast_with_comments[node.def_type? ? node : node]
            return nil if comments.nil? || comments.empty?

            # Find comments directly above this node
            first_comment = nil
            comments.reverse_each do |comment|
              if comment.source_range.line == node.source_range.line - 1 ||
                 (first_comment && comment.source_range.line == first_comment.source_range.line - 1)
                first_comment = comment
              end
            end
            first_comment
          end

          def build_replacement(sorted, indent, original_methods)
            lines = []
            prev_visibility = nil

            sorted.each_with_index do |method_info, i|
              # Add blank line between visibility sections
              if prev_visibility && method_info[:visibility] != prev_visibility
                lines << ''
                # Add visibility marker
                lines << "#{indent}#{method_info[:visibility]}"
                lines << ''
              end

              source = method_info[:node].source
              lines << (i.zero? ? source : "#{indent}#{source}")
              prev_visibility = method_info[:visibility]
            end

            lines.join("\n")
          end
        end
      end
    end
  end
end
