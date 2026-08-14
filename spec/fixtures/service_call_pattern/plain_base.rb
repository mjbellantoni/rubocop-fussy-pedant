# frozen_string_literal: true

# A base class that does NOT define `self.call`.
class PlainBase
  def something
    "not a call"
  end
end
