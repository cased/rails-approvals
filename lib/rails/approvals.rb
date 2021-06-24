require "rails/approvals/version"
require "rails/approvals/engine"
require "rails/approvals/railtie"
require "tty/prompt"
require "slack-ruby-client"

module Rails
  module Approvals
    def self.slack
      @slack ||= Slack::Web::Client.new(token: Rails.application.config.rails.approvals.slack.token)
    end
  end
end
