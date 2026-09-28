# frozen_string_literal: true

# MemoizationBody declines the single-statement no-rescue shape on the
# grounds that core Style/RedundantBegin owns it. That division is
# load-bearing -- it is the reason the cop skips a shape it otherwise
# fits -- and it is an agreement with a cop in another gem that this
# one neither controls nor configures. Asserted only in a comment, the
# failure mode is silent: if core stops reporting that shape, or starts
# reporting the ones this gem claims, nothing goes red and consumers
# just get less than they think.
#
# These examples pin the partition from both sides, so a core upgrade
# that breaks it breaks the build instead. They describe core's cop,
# not this gem's, which is why they live in their own file.
RSpec.describe RuboCop::Cop::Style::RedundantBegin, :config do
  let(:config) { RuboCop::Config.new }

  it 'reports the single-statement shape MemoizationBody skips' do
    expect_offense(<<~RUBY)
      def totals
        @totals ||= begin
                    ^^^^^ Style/RedundantBegin: Redundant `begin` block detected.
          rows.sum(&:amount)
        end
      end
    RUBY
  end

  it 'is silent on the multi-statement shape MemoizationBody reports' do
    expect_no_offenses(<<~RUBY)
      def totals
        @totals ||= begin
          rows = load_rows
          rows.sum(&:amount)
        end
      end
    RUBY
  end

  it 'is silent on the rescue-bearing shape MemoizationBody reports' do
    expect_no_offenses(<<~RUBY)
      def payload
        @payload ||= begin
          message.parsed
        rescue JSON::ParserError
          {}
        end
      end
    RUBY
  end

  it 'is silent on the empty begin neither cop reports' do
    expect_no_offenses(<<~RUBY)
      def totals
        @totals ||= begin
        end
      end
    RUBY
  end
end
