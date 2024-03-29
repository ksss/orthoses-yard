# Orthoses::YARD

Orthoses extention for [YARD](https://github.com/lsegal/yard).

`Orthoses::YARD` automatically generate RBS from YARD comment for methods.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add orthoses-yard

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install orthoses-yard

## Example

from

```rb
class Foo
  # @param [Boolean] a
  # @param [String, nil] b
  # @param [Array<Float>] c
  # @param [String] d
  # @param [Symbol, nil] e
  # @param [Hash{Symbol => String, nil}] f
  # @return [void]
  def foo(a, b = nil, *c, d:, e: nil, **f)
    1
  end
end
```

to

```rbs
class Foo
  # @param [Boolean] a
  # @param [String, nil] b
  # @param [Array<Float>] c
  # @param [String] d
  # @param [Symbol, nil] e
  # @param [Hash{Symbol => String, nil}] f
  # @return [void]
  def foo: (bool a, ?String? b, *Array[Float] c, d: String, ?e: Symbol?, **Hash[Symbol, String?] f) -> void
end
```

## Usage

```rb
use Orthoses::YARD,
  parse: ['{lib,app}/**/*.rb'], # Target files (require)
  use_cache: true,              # Use cache .yardoc database (optional default=true)
  log_level: :debug             # Set log level for YARD (optional default=nil)
```

Please see also https://github.com/ksss/orthoses-yard/blob/main/examples/yard/generate.rb

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ksss/orthoses-yard. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ksss/orthoses-yard/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Orthoses::Yard project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ksss/orthoses-yard/blob/main/CODE_OF_CONDUCT.md).

# TODO

- [ ] Add yard docstring
- [ ] Support @yieldparam, @yieldreturn tag
- [ ] Support @option tag
- [ ] Support interface (e.g. #read)
- [ ] Support generics
