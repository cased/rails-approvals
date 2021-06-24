module Rails
  module Approvals
    class Engine < ::Rails::Engine
      isolate_namespace Rails::Approvals

      config.rails = ActiveSupport::OrderedOptions.new
      config.rails.approvals = ActiveSupport::OrderedOptions.new
      config.rails.approvals.enabled = ::Rails.env.production?
      config.rails.approvals.timeout_duration = 5.minutes

      # Reason
      config.rails.approvals.reasons = ActiveSupport::OrderedOptions.new
      config.rails.approvals.reasons.required = true

      # When a reason is required, this option is ignored. If a reason is not
      # required, you can choose to prompt for a reason or not.
      config.rails.approvals.reasons.prompt = true

      # Slack
      config.rails.approvals.slack = ActiveSupport::OrderedOptions.new
      config.rails.approvals.slack.channel = ENV['RAILS_APPROVALS_SLACK_CHANNEL']
      config.rails.approvals.slack.token = ENV['RAILS_APPROVALS_SLACK_TOKEN']
      config.rails.approvals.slack.client_id = ENV['RAILS_APPROVALS_SLACK_CLIENT_ID']
      config.rails.approvals.slack.client_secret = ENV['RAILS_APPROVALS_SLACK_CLIENT_SECRET']
      config.rails.approvals.slack.signing_secret = ENV['RAILS_APPROVALS_SLACK_SIGNING_SECRET']
    end
  end
end
