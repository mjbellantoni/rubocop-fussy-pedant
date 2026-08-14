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
  ServicesDirectory: ''
  Include:
    - 'app/services/**/*.rb'
```

Rules 1-4 work out of the box. Rule 5 (no direct `.new` instantiation) requires setting `ServicesDirectory` so the cop can check whether a class is a service by looking for its file on disk:

```yaml
FussyPedant/Rails/ServiceCallPattern:
  ServicesDirectory: app/services
```

**Exemptions.** Two kinds of class that live under `app/services` are not services and are skipped:

- **`Data.define` value objects** — a constant defined as `Foo = Data.define(...)` or `class Foo < Data.define(...)` is treated as a value object. It is not required to implement `self.call`, and its `.new` calls are not flagged.
- **Inherited `self.call`** — a service that inherits `def self.call` from a base class (for example `class RentManager < Extractors::Base`) is not flagged for a missing `self.call`, as long as the base class file can be resolved via the same `ServicesDirectory` lookup used by Rule 5. If the base cannot be resolved, the cop falls back to requiring a local `self.call`.

The cop skips exception classes, modules, and allows `.new` calls within a service's own `self.call` method and in spec files.
