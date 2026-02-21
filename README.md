# rubocop-fussy-pedant

Custom RuboCop cops for Ruby, Rails, RSpec, and FactoryBot.

## Installation

Add to your `Gemfile`:

```ruby
gem 'rubocop-fussy-pedant', require: false
```

Then add to your `.rubocop.yml`:

```yaml
plugins:
  - rubocop-fussy-pedant
```

## Cops

### FussyPedant/FactoryBot/TraitsAlphabeticalOrder

Enforces that FactoryBot traits are defined in alphabetical order within factory definitions. Supports autocorrect.

```ruby
# bad
FactoryBot.define do
  factory :user do
    trait :with_posts do
      # ...
    end

    trait :admin do
      # ...
    end
  end
end

# good
FactoryBot.define do
  factory :user do
    trait :admin do
      # ...
    end

    trait :with_posts do
      # ...
    end
  end
end
```

**Default configuration:**

```yaml
FussyPedant/FactoryBot/TraitsAlphabeticalOrder:
  Enabled: true
  Include:
    - 'spec/support/factories/**/*.rb'
```

### FussyPedant/Rails/ServiceCallPattern

Enforces service object pattern conventions:

1. Services must implement `def self.call(...)`
2. Methods must be ordered: `self.call`, `initialize`, `call`, `private`
3. No custom public class methods (only `.call`)
4. Public instance method must be named `call`
5. Services should not be directly instantiated with `.new` (use `.call`)

```ruby
# bad
class MyService
  def self.perform(foo:)
    new(foo:).perform
  end

  def initialize(foo:)
    @foo = foo
  end

  def perform
    # ...
  end
end

# good
class MyService
  def self.call(...)
    new(...).call
  end

  def initialize(foo:)
    @foo = foo
  end

  def call
    # ...
  end

  private

  def helper_method
    # ...
  end
end
```

**Default configuration:**

```yaml
FussyPedant/Rails/ServiceCallPattern:
  Enabled: true
  Include:
    - 'app/services/**/*.rb'
```

The cop skips exception classes, modules, and allows `.new` calls within a service's own `self.call` method and in spec files.
