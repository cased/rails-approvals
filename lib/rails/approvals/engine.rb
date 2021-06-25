module Rails
  module Approvals
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Approvals

      config.rails = ActiveSupport::OrderedOptions.new
      config.rails.approvals = ActiveSupport::OrderedOptions.new
      config.rails.approvals.enabled = ::Rails.env.production?

      # How long you'd like approvals to last before they timed out and have to
      # be requested again. Can disable timeouts by setting this to `false`.
      config.rails.approvals.timeout_duration = 10.minutes

      # Requester
      config.rails.approvals.requester = ActiveSupport::OrderedOptions.new

      # Some environments can be trusted that the user will be present in the
      # USER environment variable. In environments where there are not per-user
      # accounts or shared environments such as Heroku, prompting the user for
      # who they are may be necessary.
      #
      # This is enabled by default for users who've installed the Dyno metadata
      # buildpack: https://devcenter.heroku.com/articles/dyno-metadata
      heroku = ENV['HEROKU_APP_NAME'].present?

      # If you are on AWS and have not set up per-user accounts, prompts will be
      # enabled by default.
      default_user = %w[ec2-user root].include?(ENV['USER'])

      config.rails.approvals.requester.prompt = heroku || default_user

      # Reason
      config.rails.approvals.reasons = ActiveSupport::OrderedOptions.new
      config.rails.approvals.reasons.required = true

      # When a reason is required, this option is ignored. If a reason is not
      # required, you can choose to prompt for a reason or not.
      config.rails.approvals.reasons.prompt = true

      # Slack
      config.rails.approvals.slack = ActiveSupport::OrderedOptions.new

      # The Slack channel you wish to send approval requests to. If the channel
      # is private you must invite the bot user associated with your Slack
      # application before rails-approvals can send messages to the channel.
      #
      # @example
      #   #approvals
      config.rails.approvals.slack.channel = ENV['RAILS_APPROVALS_SLACK_CHANNEL']

      # For rails-approvals to be authenticated for your Slack workspace, you
      # must provide the Bot User OAuth Token obtained after installing the
      # Slack application to your workspace.
      #
      # @see https://api.slack.com/apps/$app/oauth
      config.rails.approvals.slack.token = ENV['RAILS_APPROVALS_SLACK_TOKEN']

      # The signing secret is used to verify the webhook message from Slack
      # before handling it. You can obtain this from the Basic Information tab
      # within your application's Settings.
      #
      # @see https://api.slack.com/apps/$appid/general
      config.rails.approvals.slack.signing_secret = ENV['RAILS_APPROVALS_SLACK_SIGNING_SECRET']
    end
  end
end
