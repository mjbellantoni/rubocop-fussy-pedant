# frozen_string_literal: true

module Extractors
  # Base class that provides an inherited `self.call` for subclasses.
  class Base
    def self.call(...)
      new(...).call
    end

    def initialize(*)
    end

    def call
      raise NotImplementedError
    end
  end
end
