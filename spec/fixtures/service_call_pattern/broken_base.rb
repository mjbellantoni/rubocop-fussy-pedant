# frozen_string_literal: true

# A base class with a deliberate syntax error, used to prove the cop
# falls back gracefully when a resolved superclass file cannot be parsed.
class BrokenBase
  def self.call( # syntax error
end
