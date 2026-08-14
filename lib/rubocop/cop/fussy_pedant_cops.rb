# frozen_string_literal: true

# Require all FussyPedant cops here.
# As cops are added, add a require_relative line for each one.

require_relative 'fussy_pedant/factory_bot/traits_alphabetical_order'
require_relative 'fussy_pedant/rails/association_order'
require_relative 'fussy_pedant/rails/controller_method_order'
require_relative 'fussy_pedant/rails/enum_order'
require_relative 'fussy_pedant/rails/service_call_pattern'
require_relative 'fussy_pedant/rspec/model_spec_describe_format'
require_relative 'fussy_pedant/rspec/model_spec_method_order'
require_relative 'fussy_pedant/rspec/no_wait'
require_relative 'fussy_pedant/rspec/request_spec_order'
require_relative 'fussy_pedant/rspec/service_describe_call'
require_relative 'fussy_pedant/ruby/comment_line_length'
require_relative 'fussy_pedant/ruby/no_non_ascii_in_comment'
require_relative 'fussy_pedant/ruby/no_single_line_case_body'
require_relative 'fussy_pedant/ruby/no_terminal_guard_clause'
require_relative 'fussy_pedant/ruby/space_inside_percent_array'
