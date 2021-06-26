# Rails::Approvals

Add approval processes for Rails console access, running database migrations, and more in production. Be notified of approval requests and respond to them directly in Slack.

<img width="868" alt="CleanShot 2021-06-25 at 20 37 49@2x" src="https://user-images.githubusercontent.com/79995/123500785-5eda4a00-d5f5-11eb-9c39-5b704f62d2b5.png">

## Installation

Rails::Approvals requires a Slack application installed in your Slack workspace. The Slack application gives Rails::Approvals the ability to post approval requests to your configured Slack channel and other workspace users can respond to approval requests.

This guide will walk you through the process of installing the gem, configuring Slack, and `rails-approvals` to meet your needs.

### Install the rails-approvals gem

First, you must add the following line to your application's Gemfile to install `rails-approvals`:

```ruby
gem 'rails-approvals'
```

And then execute:

```bash
$ bundle
```

Or add it `rails-approvals` automatically to your `Gemfile` with:

```bash
$ bundle add rails-approvals
```

### Create Slack application

Now that you have the gem installed, it's time to create the Rails Approvals Slack application for your Slack workspace. To create a Slack application you must be a Slack workspace administrator.

Using the link below a new Slack application will be prefilled with all settings and scopes required for Rails::Approvals to work. Slack will prompt you to verify the permissions that will be granted before you create the Slack application.

<a href="https://api.slack.com/apps?new_app=1&manifest_json=%7B%0A%20%20%22_metadata%22%3A%20%7B%0A%20%20%20%20%22major_version%22%3A%201%2C%0A%20%20%20%20%22minor_version%22%3A%201%0A%20%20%7D%2C%0A%20%20%22display_information%22%3A%20%7B%0A%20%20%20%20%22name%22%3A%20%22Rails%20Approvals%22%0A%20%20%7D%2C%0A%20%20%22features%22%3A%20%7B%0A%20%20%20%20%22app_home%22%3A%20%7B%0A%20%20%20%20%20%20%22home_tab_enabled%22%3A%20false%2C%0A%20%20%20%20%20%20%22messages_tab_enabled%22%3A%20true%2C%0A%20%20%20%20%20%20%22messages_tab_read_only_enabled%22%3A%20true%0A%20%20%20%20%7D%2C%0A%20%20%20%20%22bot_user%22%3A%20%7B%0A%20%20%20%20%20%20%22display_name%22%3A%20%22Rails%20Approvals%22%2C%0A%20%20%20%20%20%20%22always_online%22%3A%20false%0A%20%20%20%20%7D%0A%20%20%7D%2C%0A%20%20%22oauth_config%22%3A%20%7B%0A%20%20%20%20%22scopes%22%3A%20%7B%0A%20%20%20%20%20%20%22bot%22%3A%20%5B%0A%20%20%20%20%20%20%20%20%22chat%3Awrite%22%0A%20%20%20%20%20%20%5D%0A%20%20%20%20%7D%0A%20%20%7D%2C%0A%20%20%22settings%22%3A%20%7B%0A%20%20%20%20%22interactivity%22%3A%20%7B%0A%20%20%20%20%20%20%22is_enabled%22%3A%20true%2C%0A%20%20%20%20%20%20%22request_url%22%3A%20%22https%3A%2F%2Fwebsite.com%2Frails%2Fapprovals%2Fslack%2Fwebhook%22%0A%20%20%20%20%7D%2C%0A%20%20%20%20%22org_deploy_enabled%22%3A%20false%2C%0A%20%20%20%20%22socket_mode_enabled%22%3A%20false%0A%20%20%7D%0A%7D%0A"><img alt="Add to Slack" height="40" width="139" src="https://platform.slack-edge.com/img/add_to_slack@2x.png" /></a>

Later in this installation guide you will be instructed to configure the webhook URL that Rails::Approvals needs to handle approval request responses within Slack's settings.

If you'd like to setup the Slack application manually you can do so following [Setup Slack Application](#setup-slack-application) guide below.

### Configuring rails-approvals

Rails::Approvals needs three things to work:

1. The **Slack Bot User OAuth Token** generated after installing the Slack application to your workspace. This lets the gem publish messages to your configured Slack channel.
1. The **Webhook signing secret** generated by Slack.
1. The **Slack channel** you'd like to send approval requests to.

Each of these can be configured by environment variables or manually in your environment file. We strongly do not recommend checking in any API tokens into version control and using environment variables to configure them.

```ruby
Rails.application.configure do
  # Enabled by default in production. If you'd like to enable approvals in
  # staging or other environments you can do so here.
  config.rails.approvals.enabled = true

  # Can be configured with RAILS_APPROVALS_SLACK_CHANNEL by default, or provided
  # explicitely.
  config.rails.approvals.slack.channel = "#rails-approvals"

  # Can be configured with RAILS_APPROVALS_SLACK_TOKEN. Strongly do not
  # recommended checking this into version control.
  config.rails.approvals.slack.token = ENV['RAILS_APPROVALS_SLACK_TOKEN']

  # Can be configured with RAILS_APPROVALS_SLACK_SIGNING_SECRET. Strongly do not
  # recommended checking this into version control.
  config.rails.approvals.slack.signing_secret = ENV['RAILS_APPROVALS_SLACK_SIGNING_SECRET']
end
```

There are [additional settings](https://github.com/cased/rails-approvals/blob/main/lib/rails/approvals/engine.rb) you can configure should you like, such as:

- How long approval requests are valid for (defaults to 10 minutes)
- If the user is prompted to identify who they are (defaults to $USER)
- If a reason is required.

### Mounting the Rails::Approvals engine

When you respond to approval requests within Slack, Slack will deliver a webhook
message to your configured application to permit or deny access accordingly. Rails::Approvals includes a built in controller to verify the message from Slack using the required signing secret, lookup the approval request, and handle the approved/denied response.

You will want to mount the `Rails::Approvals::Engine` within your `config/routes.rb` file:

```ruby
Rails.application.routes.draw do
  mount Rails::Approvals::Engine => "/rails/approvals"

  # existing routes here
end
```

For Slack to know where to send approval request responses you must provide a webhook URL. Using the URL below, replace `example.com` with your application's domain and enter it within the **Interactivity & Shortcuts** section of your Slack application settings:

```
https://example.com/rails/approvals/slack/webhook
```

### Run the database migration

Rails::Approvals uses an ActiveRecord model to keep track of all pending approval requests, who requested them, the reason provided and more. Install and run the required database migration below:

```
bin/rails railsapprovals:install:migrations
bin/rails db:migrate
```

You are welcome to check out the [migration](https://github.com/cased/rails-approvals/blob/main/db/migrate/20210624220156_create_rails_approvals_requests.rb) before running
it.

### Deploy

Now that you've installed `rails-approvals`, setup your Slack application & installed it to your workspace, you're ready to go!

## How does Rails::Approvals work?

Rails::Approvals works by adding a blocking approval request before a Rails console can be started.

```ruby
module Rails
  module Approvals
    class Railtie < ::Rails::Railtie
      console do
        Rails::Approvals.start!
      end
    end
  end
end
```

An [`Rails::Approvals::Request`](https://github.com/cased/rails-approvals/blob/main/app/models/rails/approvals/request.rb) record is created which publishes the approval request to Slack and waits for someone to respond.

When an approval request is ✅ _approved_, the console session will continue as normal. When an approval response is 🛑 _denied_ or ⚠️ _times out_, the process will exit immediately.

## Setup Slack Application

If you'd like to create your Slack application manually, you can do so by following the instructions below:

1. Create a [new Slack application](https://api.slack.com/apps?new_app=1) for your desired Slack workspace.
1. Next, under **Features**, select **OAuth & Permissions**.
1. Add the `chat:write` scope under **Bot Token Scopes**. This is the only permission you need.
1. Now that you've added the required permission for Rails::Approvals to work, you must install the new application in your Slack workspace.
1. Under **Settings**, select **Install App**.
1. Install your Slack application to your workspace by following the prompt after clicking **Install to Workspace**.
1. Copy the **Bot User OAuth Token** and configure a `RAILS_APPROVALS_SLACK_TOKEN` environment variable for your application.
1. Next, under **Features**, select **Interactivity & Shortcuts**.
1. Enable **Interactivity** and provide the **Request URL** per the [webhook URL instructions above](#mounting-the-railsapprovals-engine).
1. Next, under **Settings**, select **Basic Information**.
1. Copy the **Signing Secret** under **App Credentials** and configure your `RAILS_APPROVALS_SLACK_SIGNING_SECRET` environment variable.

## Contributing

1. Fork it ( https://github.com/cased/rails-approvals/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
