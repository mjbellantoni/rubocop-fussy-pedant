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
        class CommentLineLength < RuboCop::Cop::Base # rubocop:disable Metrics/ClassLength
          extend RuboCop::Cop::AutoCorrector

          MSG = 'Comment line exceeds %<max>d columns. ' \
                '[%<current>d/%<max>d]'

          ANNOTATION_KEYWORDS = %w[TODO FIXME NOTE HACK OPTIMIZE REVIEW].freeze

          def on_new_investigation
            paragraphs = group_into_paragraphs(eligible_comments)
            paragraphs.each { |paragraph| check_paragraph(paragraph) }
          end

          private

          def eligible_comments
            processed_source.comments.select do |comment|
              full_line_comment?(comment) && !special_comment?(comment) &&
                !url_only_comment?(comment) && !yard_tag_comment?(comment)
            end
          end

          def group_into_paragraphs(comments)
            return [] if comments.empty?

            comments.chunk_while { |prev, curr| same_paragraph?(prev, curr) }.to_a
          end

          def same_paragraph?(prev_comment, curr_comment)
            adjacent_comments?(prev_comment, curr_comment) &&
              !paragraph_boundary?(prev_comment, curr_comment)
          end

          def adjacent_comments?(prev_comment, curr_comment)
            curr_comment.location.line == prev_comment.location.line + 1 &&
              curr_comment.source_range.column == prev_comment.source_range.column
          end

          def paragraph_boundary?(prev_comment, curr_comment)
            empty_comment?(prev_comment) ||
              empty_comment?(curr_comment) ||
              list_item_comment?(curr_comment) ||
              header_comment?(prev_comment) ||
              header_comment?(curr_comment) ||
              indent_boundary?(prev_comment, curr_comment)
          end

          def indent_boundary?(prev_comment, curr_comment)
            prev_spaces = spaces_after_hash(prev_comment)
            curr_spaces = spaces_after_hash(curr_comment)
            return false if prev_spaces == curr_spaces

            # List item followed by continuation at marker indent
            if list_item_comment?(prev_comment)
              expected = 1 + list_marker_width(prev_comment)
              return false if curr_spaces == expected
            end

            true
          end

          def spaces_after_hash(comment)
            match = comment.text.match(/\A#(\s*)\S/)
            match ? match[1].length : 0
          end

          def empty_comment?(comment)
            comment.text.match?(/\A#\s*\z/)
          end

          def list_item_comment?(comment)
            comment.text.match?(/\A#\s+(?:[-*]\s|\d+\.\s)/)
          end

          def list_marker_width(comment)
            match = comment.text.match(/\A#\s(?:[-*]\s|\d+\.\s)/)
            match ? match[0].length - 2 : 0
          end

          def header_comment?(comment)
            comment.text.match?(/\A#\s+\S.*:\s*\z/)
          end

          def unwrappable_paragraph?(paragraph)
            extract_words(paragraph).length == 1
          end

          def code_paragraph?(paragraph)
            !list_item_comment?(paragraph.first) &&
              paragraph.all? { |comment| spaces_after_hash(comment) >= 3 }
          end

          def check_paragraph(paragraph)
            return if unwrappable_paragraph?(paragraph)
            return if code_paragraph?(paragraph)

            overlength = paragraph.find { |comment| line_length(comment) > max_column }
            return unless overlength

            message = format(MSG, current: line_length(overlength), max: max_column)
            add_offense(overlength, message: message) do |corrector|
              rewrap_paragraph(corrector, paragraph)
            end
          end

          def rewrap_paragraph(corrector, paragraph)
            indent = paragraph.first.source_range.column
            replacement = build_replacement(paragraph, indent)
            range = paragraph.first.source_range.join(paragraph.last.source_range)
            corrector.replace(range, replacement)
          end

          def build_replacement(paragraph, indent)
            cont_indent = list_marker_width(paragraph.first)
            first_width = max_column - indent - 2
            rest_width = first_width - cont_indent
            words = extract_words(paragraph)
            new_lines = wrap_words(words, first_width, rest_width)
            format_lines(new_lines, indent, cont_indent)
          end

          def format_lines(lines, indent, cont_indent = 0)
            rest_prefix = "#{' ' * indent}# #{' ' * cont_indent}"
            lines.each_with_index.map do |line, i|
              i.zero? ? "# #{line}" : "#{rest_prefix}#{line}"
            end.join("\n")
          end

          def extract_words(paragraph)
            paragraph.flat_map do |comment|
              comment.text.sub(/\A#\s?/, '').split(/\s+/)
            end.reject(&:empty?)
          end

          def wrap_words(words, first_width, rest_width = first_width)
            words.each_with_object([+'']) do |word, lines|
              append_word(lines, word, lines.length == 1 ? first_width : rest_width)
            end
          end

          def append_word(lines, word, width)
            if lines.last.empty?
              lines.last << word
            elsif lines.last.length + 1 + word.length <= width
              lines.last << ' ' << word
            else
              lines << +word
            end
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

          def yard_tag_comment?(comment)
            comment.text.match?(/\A#\s+@\w/)
          end

          def url?(word)
            word.match?(%r{\Ahttps?://\S+\z})
          end

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
