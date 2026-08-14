# frozen_string_literal: true

# A Data.define value object defined via class + superclass form.
class Coordinate < Data.define(:lat, :lng)
end
