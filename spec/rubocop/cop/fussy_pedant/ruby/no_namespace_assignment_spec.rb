# frozen_string_literal: true

RSpec.describe RuboCop::Cop::FussyPedant::Ruby::NoNamespaceAssignment, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense for constant resolution through a local variable' do
    expect_offense(<<~RUBY)
      ns = Integrations::CorpusImport
      ns::FieldMapping.new
      ^^^^^^^^^^^^^^^^ FussyPedant/Ruby/NoNamespaceAssignment: Reference the namespace directly instead of resolving a constant through a local variable.
    RUBY
  end

  it 'accepts direct constant resolution' do
    expect_no_offenses('Integrations::CorpusImport::FieldMapping.new')
  end

  it 'accepts calling a method on a local variable' do
    expect_no_offenses(<<~RUBY)
      klass = Foo
      klass.new
    RUBY
  end
end
