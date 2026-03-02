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
            paragraphs = group_into_paragraphs(eligible_comments)
            paragraphs.each { |paragraph| check_paragraph(paragraph) }
          end

          private

          def eligible_comments
            processed_source.comments.select do |comment|
              full_line_comment?(comment) && !special_comment?(comment) && !url_only_comment?(comment)
            end
          end

          def group_into_paragraphs(comments)
            return [] if comments.empty?

            paragraphs = []
            current_paragraph = [comments.first]

            comments.each_cons(2) do |prev, curr|
              if same_paragraph?(prev, curr)
                current_paragraph << curr
              else
                paragraphs << current_paragraph
                current_paragraph = [curr]
              end
            end

            paragraphs << current_paragraph
            paragraphs
          end

          def same_paragraph?(prev_comment, curr_comment)
            curr_comment.location.line == prev_comment.location.line + 1 &&
              curr_comment.source_range.column == prev_comment.source_range.column &&
              !empty_comment?(curr_comment)
          end

          def empty_comment?(comment)
            comment.text.match?(/\A#\s*\z/)
          end

          def unwrappable_paragraph?(paragraph)
            words = extract_words(paragraph)
            words.length == 1
          end

          def check_paragraph(paragraph)
            return if unwrappable_paragraph?(paragraph)

            overlength = paragraph.find do |comment|
              line_length(comment) > max_column
            end

            return unless overlength

            add_offense(overlength, message: format(MSG, current: line_length(overlength), max: max_column)) do |corrector|
              rewrap_paragraph(corrector, paragraph)
            end
          end

          def rewrap_paragraph(corrector, paragraph)
            indent = paragraph.first.source_range.column
            available_width = max_column - indent - 2 # indent + "# "

            words = extract_words(paragraph)
            new_lines = wrap_words(words, available_width)

            # source_range starts at #, not at leading whitespace
            # First line: just "# " prefix (cursor already at column)
            # Subsequent lines: full indent + "# "
            rest_prefix = "#{' ' * indent}# "
            replacement = new_lines.each_with_index.map do |line, i|
              i.zero? ? "# #{line}" : "#{rest_prefix}#{line}"
            end.join("\n")

            range = paragraph.first.source_range.join(paragraph.last.source_range)
            corrector.replace(range, replacement)
          end

          def extract_words(paragraph)
            paragraph.flat_map do |comment|
              text = comment.text.sub(/\A#\s?/, '')
              text.split(/\s+/)
            end.reject(&:empty?)
          end

          def wrap_words(words, available_width)
            lines = []
            current_line = +''

            words.each do |word|
              if current_line.empty?
                current_line << word
              elsif current_line.length + 1 + word.length <= available_width
                current_line << ' ' << word
              else
                lines << current_line
                current_line = +word
              end
            end

            lines << current_line unless current_line.empty?
            lines
          end

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

          def url_only_comment?(comment)
            text = comment.text.sub(/\A#\s?/, '')
            url?(text)
          end

          def url?(word)
            word.match?(%r{\Ahttps?://\S+\z})
          end

          ANNOTATION_KEYWORDS = %w[TODO FIXME NOTE HACK OPTIMIZE REVIEW].freeze

          def special_comment?(comment)
            text = comment.text
            shebang?(text) ||
              rubocop_directive?(text) ||
              magic_comment?(text) ||
              annotation_comment?(text)
          end

          def shebang?(text)
            text.start_with?('#!')
          end

          def rubocop_directive?(text)
            text.match?(/\A#\s*rubocop:\s*(?:disable|enable|todo)\b/)
          end

          def magic_comment?(text)
            text.match?(/\A#\s*(?:frozen_string_literal|encoding|warn_indent|sharable_constant_value|typed):\s/)
          end

          def annotation_comment?(text)
            stripped = text.sub(/\A#\s*/, '')
            ANNOTATION_KEYWORDS.any? do |kw|
              stripped.start_with?("#{kw}:") ||
                stripped.start_with?("#{kw} ") ||
                stripped == kw
            end
          end
        end
      end
    end
  end
end
