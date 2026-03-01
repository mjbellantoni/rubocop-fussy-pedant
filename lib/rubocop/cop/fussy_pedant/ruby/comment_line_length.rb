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
            # TODO: implement
          end
        end
      end
    end
  end
end
