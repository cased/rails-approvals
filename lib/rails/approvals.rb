require "rails/approvals/version"
require "rails/approvals/engine"
require "rails/approvals/railtie"
require "tty/prompt"
require "slack-ruby-client"

module Rails
  module Approvals
    def self.start!
      # We only want to start an approval request if it's enabled.
      return unless ::Rails.application.config.rails.approvals.enabled

      if Rails.application.config.rails.approvals.slack.token.blank?
        msg = <<~MSG
        Please provide your Slack API token either in the `RAILS_APPROVALS_SLACK_TOKEN` environment variable, or configured in your environment file:

        Rails.application.configure do
          config.rails.approvals.enabled = true
          config.rails.approvals.slack.channel = "#rails-approvals"
          config.rails.approvals.slack.token = "your-token-here"
        end
        MSG

        puts msg
        exit 1
      end

      request = Rails::Approvals.await
      case
      when request.approved?
        puts "Request approved by #{request.responder}"
      when request.denied?
        puts "Request denied by #{request.responder}"
        exit 1
      when request.timed_out?
        puts "Request timed out"
        exit 1
      when request.canceled?
        puts "Request canceled"
        exit 0
      end
    rescue TTY::Reader::InputInterrupt
      exit 0
    end

    def self.await
      request = Rails::Approvals::Request.request!
      poll = request.requested?
      canceled = false

      Signal.trap('SIGINT') do
        # Stop the polling
        poll = false

        # Canceling the request inside of a trap will fail if it results in
        # any log output. Cancel the request outside of the scope of the trap
        # and everything will work as expected.
        canceled = true
      end

      while poll
        if request.expired?
          request.timed_out!
          break
        end

        request.reload
        poll = request.requested?

        sleep 0.1
      end

      if canceled
        request.canceled!
      end

      request
    end

    def self.slack
      @slack ||= Slack::Web::Client.new(token: Rails.application.config.rails.approvals.slack.token)
    end
  end
end
