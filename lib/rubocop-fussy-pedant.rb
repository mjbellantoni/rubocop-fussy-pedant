# frozen_string_literal: true

require 'rubocop'

RuboCop::ConfigObsoletion.files << File.expand_path(
  '../config/obsoletion.yml', __dir__
)

require_relative 'rubocop/fussy_pedant/version'
require_relative 'rubocop/fussy_pedant/plugin'

require_relative 'rubocop/cop/fussy_pedant_cops'
