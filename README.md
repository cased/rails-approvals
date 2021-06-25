# Rails::Approvals

Add approval processes for Rails console access, running database migrations, and more in production. Be notified of approval requests and respond to them directly in Slack.

## Usage

How to use my plugin.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-approvals'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install rails-approvals
```

## Slack

- `groups:read`, `channels:read`, `chat:write`
- If the channel is private, you must invite the bot user to the channel first.

## Contributing

1. Fork it ( https://github.com/cased/rails-approvals/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
