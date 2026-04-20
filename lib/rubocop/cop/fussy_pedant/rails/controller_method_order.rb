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

          VISIBILITY_METHODS = { public: :public, protected: :protected, private: :private }.freeze
          VISIBILITY_RANKS = { public: 0, protected: 1, private: 2 }.freeze

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
            result = { methods: [], visibility: :public }
            class_node.body&.each_child_node { |child| process_child(child, result) }
            result[:methods]
          end

          def process_child(child, result)
            case child.type
            when :send
              result[:visibility] = process_send(child, result[:visibility], result[:methods])
            when :def
              result[:methods] << build_method(child, result[:visibility], child)
            end
          end

          def process_send(child, visibility, methods)
            new_vis = VISIBILITY_METHODS[child.method_name]
            return visibility unless new_vis
            return new_vis if child.arguments.empty?

            inner_def = child.first_argument
            methods << build_method(inner_def, new_vis, child) if inner_def&.def_type?
            visibility
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
            vis_rank = VISIBILITY_RANKS[method_info[:visibility]]
            sub_rank = public_rest?(method_info) ? 0 : 1
            [vis_rank, sub_rank, method_info[:rest_rank], method_info[:name].to_s]
          end

          def public_rest?(method_info)
            method_info[:visibility] == :public && method_info[:rest_action]
          end

          def check_ordering(methods)
            sorted = methods.sort_by { |m| sort_key(m) }

            methods.each_with_index do |method_info, i|
              expected = sorted[i]
              next if method_info[:name] == expected[:name]

              message = build_message(method_info, sorted, i)
              add_offense(method_info[:def_node], message: message) do |corrector|
                autocorrect_methods(corrector, methods)
              end
            end
          end

          def build_message(method_info, sorted, index)
            expected = sorted[index]
            return section_order_message(expected, method_info) if method_info[:visibility] != expected[:visibility]
            return rest_order_message(expected, method_info) if method_info[:rest_action] && expected[:rest_action]

            alphabetical_message(expected, method_info)
          end

          def section_order_message(expected, actual)
            format(MSG_SECTION_ORDER,
                   visibility: expected[:visibility], method: expected[:name],
                   other_visibility: actual[:visibility], other: actual[:name])
          end

          def rest_order_message(expected, actual)
            format(MSG_REST_ORDER, method: expected[:name], other: actual[:name])
          end

          def alphabetical_message(expected, actual)
            format(MSG_ALPHABETICAL,
                   method: expected[:name], other: actual[:name],
                   visibility: actual[:visibility])
          end

          def autocorrect_methods(corrector, methods)
            sorted = methods.sort_by { |m| sort_key(m) }
            range = method_range(methods)
            indent = ' ' * range.column
            corrector.replace(range, build_replacement(sorted, indent))
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
            comments = processed_source.ast_with_comments[node]
            return nil if comments.nil? || comments.empty?

            find_contiguous_comment_above(comments, node)
          end

          def find_contiguous_comment_above(comments, node)
            first_comment = nil
            comments.reverse_each do |comment|
              target_line = first_comment ? first_comment.source_range.line - 1 : node.source_range.line - 1
              first_comment = comment if comment.source_range.line == target_line
            end
            first_comment
          end

          def build_replacement(sorted, indent)
            lines = []
            prev_visibility = nil

            sorted.each_with_index do |method_info, i|
              sep = visibility_separator(method_info, prev_visibility, indent)
              lines.concat(sep)
              lines << if i.zero?
                         method_info[:node].source
                       elsif sep.any?
                         "#{indent}#{method_info[:node].source}"
                       else
                         "\n#{indent}#{method_info[:node].source}"
                       end
              prev_visibility = method_info[:visibility]
            end

            lines.join("\n")
          end

          def visibility_separator(method_info, prev_visibility, indent)
            return [] unless prev_visibility && method_info[:visibility] != prev_visibility

            ['', "#{indent}#{method_info[:visibility]}", '']
          end
        end
      end
    end
  end
end
