# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module RSpec
        # Enforces ordering of top-level describe blocks in request
        # specs: REST actions in canonical order, then non-REST
        # alphabetically.
        #
        # REST actions are identified by HTTP verb + path pattern:
        #   GET /resources       → index
        #   GET /resources/:id   → show
        #   GET /resources/new   → new
        #   POST /resources      → create
        #   GET /resources/:id/edit → edit
        #   PATCH /resources/:id → update
        #   PUT /resources/:id   → update
        #   DELETE /resources/:id → destroy
        #
        # @example
        #   # bad
        #   RSpec.describe '/users' do
        #     describe 'DELETE /users/:id' do; end
        #     describe 'GET /users' do; end
        #   end
        #
        #   # good
        #   RSpec.describe '/users' do
        #     describe 'GET /users' do; end
        #     describe 'DELETE /users/:id' do; end
        #   end
        class RequestSpecOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          DEFAULT_REST_ACTIONS = %i[
            index show new create edit update destroy
          ].freeze

          MSG = 'Expected `%<expected>s` to come before `%<actual>s`.'

          REST_PATTERNS = {
            %w[GET collection] => :index,
            %w[GET member] => :show,
            %w[GET new] => :new,
            %w[POST collection] => :create,
            %w[GET edit] => :edit,
            %w[PATCH member] => :update,
            %w[PUT member] => :update,
            %w[DELETE member] => :destroy
          }.freeze

          def on_block(node)
            return unless rspec_describe?(node)

            describes = collect_child_describes(node)
            return if describes.size < 2

            check_ordering(describes)
          end
          alias on_numblock on_block

          private

          def rest_actions
            @rest_actions ||= (cop_config['RestActions'] || DEFAULT_REST_ACTIONS).map(&:to_sym)
          end

          def rspec_describe?(node)
            send_node = node.send_node
            send_node.receiver&.const_name == 'RSpec' &&
              send_node.method_name == :describe
          end

          def collect_child_describes(node)
            return [] unless node.body

            node.body.each_child_node(:block, :numblock).filter_map do |child|
              next unless child.send_node.method_name == :describe

              build_describe_info(child)
            end
          end

          def build_describe_info(child)
            text = describe_text(child)
            return nil unless text

            action = classify_action(text)
            {
              node: child,
              text: text,
              action: action,
              rest_rank: action ? rest_actions.index(action) || Float::INFINITY : nil
            }
          end

          def describe_text(node)
            first_arg = node.send_node.first_argument
            return nil unless first_arg&.str_type?

            first_arg.value
          end

          def classify_action(text)
            match = text.match(/\A(GET|POST|PUT|PATCH|DELETE)\s+(\S+)\z/i)
            return nil unless match

            verb = match[1].upcase
            path = match[2]
            shape = path_shape(path)

            REST_PATTERNS[[verb, shape]]
          end

          def path_shape(path)
            segments = path.split('/').reject(&:empty?)
            return 'collection' if segments.size <= 1

            last = segments.last
            second_last = segments[-2]

            return 'new' if last == 'new'
            return 'edit' if last == 'edit'
            return 'member' if param_segment?(last)

            # Nested resource collection: /users/:user_id/posts
            return 'collection' if param_segment?(second_last)

            nil
          end

          def param_segment?(segment)
            return false unless segment

            segment.start_with?(':') || segment.match?(/\A\d+\z/)
          end

          def sort_key(describe_info)
            if describe_info[:rest_rank]
              [0, describe_info[:rest_rank], '']
            else
              [1, 0, describe_info[:text]]
            end
          end

          def check_ordering(describes)
            sorted = describes.sort_by { |d| sort_key(d) }

            describes.each_with_index do |desc, i|
              expected = sorted[i]
              next if desc[:text] == expected[:text]

              message = format(MSG, expected: expected[:text], actual: desc[:text])
              add_offense(desc[:node].send_node, message: message) do |corrector|
                autocorrect_describes(corrector, describes)
              end
            end
          end

          def autocorrect_describes(corrector, describes)
            sorted = describes.sort_by { |d| sort_key(d) }
            range = describe_range(describes)
            indent = ' ' * range.column
            corrector.replace(range, build_replacement(sorted, indent))
          end

          def describe_range(describes)
            first = describes.first[:node]
            last = describes.last[:node]
            first_range = include_leading_comment(first)
            first_range.join(last.source_range)
          end

          def include_leading_comment(node)
            comment = leading_comment(node)
            comment ? comment.source_range.join(node.source_range) : node.source_range
          end

          def leading_comment(node)
            comments = processed_source.ast_with_comments[node]
            return nil if comments.nil? || comments.empty?

            first_comment = nil
            comments.reverse_each do |comment|
              target_line = first_comment ? first_comment.source_range.line - 1 : node.source_range.line - 1
              first_comment = comment if comment.source_range.line == target_line
            end
            first_comment
          end

          def build_replacement(sorted, indent)
            sorted.map.with_index do |desc, i|
              if i.zero?
                desc[:node].source
              else
                "\n#{indent}#{desc[:node].source}"
              end
            end.join("\n")
          end
        end
      end
    end
  end
end
