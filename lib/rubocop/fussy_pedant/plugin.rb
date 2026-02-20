# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module FussyPedant
    # RuboCop plugin integration for rubocop-fussy-pedant.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-fussy-pedant',
          version: VERSION,
          homepage: '',
          description: 'Custom RuboCop cops for Ruby, Rails, and RSpec.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        project_root = Pathname.new(__dir__).join('../../..')

        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: project_root.join('config/default.yml')
        )
      end
    end
  end
end
