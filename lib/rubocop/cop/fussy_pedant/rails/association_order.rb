# frozen_string_literal: true

module RuboCop
  module Cop
    module FussyPedant
      module Rails
        # Enforces consistent ordering and spacing of ActiveRecord
        # association declarations within model files.
        #
        # Associations must be ordered by subtype:
        # belongs_to, has_one, has_one :through, has_many,
        # has_many :through, has_and_belongs_to_many.
        #
        # Within each subtype, associations must be alphabetical.
        #
        # When a model has 3+ associations, blank lines are required
        # between different subtypes. With fewer than 3, no blank
        # lines should appear between associations.
        #
        # @example
        #   # bad
        #   class User < ApplicationRecord
        #     has_many :posts
        #     belongs_to :company
        #   end
        #
        #   # good
        #   class User < ApplicationRecord
        #     belongs_to :company
        #     has_many :posts
        #   end
        #
        #   # good (3+ associations with spacing)
        #   class User < ApplicationRecord
        #     belongs_to :company
        #
        #     has_many :comments
        #     has_many :posts
        #   end
        class AssociationOrder < RuboCop::Cop::Base
          extend RuboCop::Cop::AutoCorrector

          ASSOCIATION_METHODS = %i[
            belongs_to has_one has_many has_and_belongs_to_many
          ].freeze

          def on_class(node)
            # TODO: implement
          end
        end
      end
    end
  end
end
