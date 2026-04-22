# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Ruby
        # Checks that comments contain only ASCII characters. LLMs
        # frequently insert typographic characters such as em-dashes,
        # smart quotes, and ellipsis that do not belong in source code.
        #
        # @example
        #   # bad
        #   # This is a comment - with an em-dash.
        #
        #   # good
        #   # This is a comment - with a plain hyphen.
        class NoNonAsciiInComment < RuboCop::Cop::Base
          MSG = 'Avoid non-ASCII characters in comments; ' \
                'use plain ASCII equivalents instead.'

          NON_ASCII = /[^\x00-\x7F]/

          def on_new_investigation
            processed_source.comments.each do |comment|
              next unless comment.text.match?(NON_ASCII)

              add_offense(comment)
            end
          end
        end
      end
    end
  end
end
