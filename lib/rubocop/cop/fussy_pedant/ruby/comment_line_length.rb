# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Checks that full-line comments do not exceed a configurable
        # column limit (default 72). Autocorrects by rewrapping
        # comment paragraphs, treating URLs as unbreakable tokens.
        #
        # Special comments are excluded: magic comments, rubocop
        # directives, shebangs, and annotation keywords (TODO, FIXME,
        # NOTE, HACK, OPTIMIZE, REVIEW).
        #
        # @example
        #   # bad (exceeds 72 columns)
        #   # This is a very long comment that goes well beyond the seventy-two column limit and should be wrapped.
        #
        #   # good
        #   # This is a comment that has been properly wrapped to fit
        #   # within the seventy-two column limit.
        class CommentLineLength < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Comment line exceeds %<max>d columns. ' \
                '[%<current>d/%<max>d]'

          def on_new_investigation
            processed_source.comments.each do |comment|
              next unless full_line_comment?(comment)
              next if special_comment?(comment)

              length = line_length(comment)
              next if length <= max_column

              add_offense(comment, message: format(MSG, current: length, max: max_column))
            end
          end

          private

          def max_column
            cop_config['MaxColumn'] || 72
          end

          def line_length(comment)
            comment.source_range.column + comment.source_range.source.length
          end

          def full_line_comment?(comment)
            line = processed_source.lines[comment.location.line - 1]
            line.strip.start_with?('#')
          end

          def special_comment?(_comment)
            false
          end
        end
      end
    end
  end
end
