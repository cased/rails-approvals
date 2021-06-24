module Rails
  module Approvals
    class Request < ApplicationRecord
      after_create_commit :publish_message_to_slack

      enum state: {
        requested: 102,
        approved: 202,
        denied: 401,
        timed_out: 408,
        canceled: 410,
      }

      before_validation :prompt_for_reason
      validates :reason, presence: ::Rails.application.config.rails.approvals.reasons.required

      def self.request
        request = create!(
          requester: ENV['USER'],
          command: [$PROGRAM_NAME, *ARGV].join(' '),
        )

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

      def expired?
        return false unless requested?

        expires_at = created_at + Rails.application.config.rails.approvals.timeout_duration
        expires_at <= Time.zone.now
      end

      private

      def prompt_for_reason
        return if reason?
        reason_required = ::Rails.application.config.rails.approvals.reasons.required
        reason_prompt = ::Rails.application.config.rails.approvals.reasons.prompt

        return if !reason_required && !reason_prompt

        prompt = TTY::Prompt.new
        reason = prompt.multiline("Please enter a reason for running #{command}:", help: '(Press Ctrl+D or Ctrl+Z to submit)')

        self.reason = reason.join("\n")
      end

      def publish_message_to_slack
        if slack_message_ts?
          Rails::Approvals.slack.chat_update(
            channel: Rails.application.config.rails.approvals.slack.channel,
            ts: slack_message_ts,
            blocks: [],
          )
        else
          message = Rails::Approvals.slack.chat_postMessage(
            channel: Rails.application.config.rails.approvals.slack.channel,
            blocks: [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "You have a new request:\n*<fakeLink.toEmployeeProfile.com|Fred Enriquez - New device request>*"
                  }
                },
                {
                  "type": "section",
                  "fields": [
                    {
                      "type": "mrkdwn",
                      "text": "*Type:*\nComputer (laptop)"
                    },
                    {
                      "type": "mrkdwn",
                      "text": "*When:*\nSubmitted Aut 10"
                    },
                    {
                      "type": "mrkdwn",
                      "text": "*Last Update:*\nMar 10, 2015 (3 years, 5 months)"
                    },
                    {
                      "type": "mrkdwn",
                      "text": "*Reason:*\nAll vowel keys aren't working."
                    },
                    {
                      "type": "mrkdwn",
                      "text": "*Specs:*\n\"Cheetah Pro 15\" - Fast, really fast\""
                    }
                  ]
                },
                {
                  "type": "actions",
                  "elements": [
                    {
                      "type": "button",
                      "text": {
                        "type": "plain_text",
                        "emoji": true,
                        "text": "Approve"
                      },
                      "style": "primary",
                      "value": "click_me_123"
                    },
                    {
                      "type": "button",
                      "text": {
                        "type": "plain_text",
                        "emoji": true,
                        "text": "Deny"
                      },
                      "style": "danger",
                      "value": "click_me_123"
                    }
                  ]
                }
              ]
          )

          update(slack_message_ts: message.ts)
        end
      end
    end
  end
end
