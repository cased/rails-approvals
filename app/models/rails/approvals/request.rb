module Rails
  module Approvals
    class Request < ApplicationRecord
      enum state: {
        requested: 102,
        approved: 202,
        denied: 401,
        timed_out: 408,
        canceled: 410,
      }

      validates :requester, presence: true
      validates :reason, presence: ::Rails.application.config.rails.approvals.reasons.required

      before_validation :prompt_for_requester
      before_validation :prompt_for_reason
      after_commit :publish_message_to_slack, on: %i[create update]

      def self.request!
        create!(
          requester: ENV['USER'],
          command: [$PROGRAM_NAME, *ARGV].join(' '),
        )
      end

      def expired?
        return false unless requested?

        timeout_duration = Rails.application.config.rails.approvals.timeout_duration
        return false if !timeout_duration

        unless timeout_duration.is_a?(Numeric) || timeout_duration.is_a?(ActiveSupport::Duration)
          raise ArgumentError, "expected ActiveSupport::Duration or Numeric value"
        end

        expires_at = created_at + Rails.application.config.rails.approvals.timeout_duration
        expires_at <= Time.zone.now
      end

      private

      def prompt_for_requester
        return if requester? && !Rails.application.config.rails.requester.prompt

        prompt = TTY::Prompt.new
        response = prompt.multiline("Who are you?", help: '(Press Ctrl+D or Ctrl+Z to submit)')

        self.requester = response.join("\n")
      end

      def prompt_for_reason
        # We already have a reason, prompting for one is unnecessary.
        return if reason?

        reason_required = ::Rails.application.config.rails.approvals.reasons.required
        reason_prompt = ::Rails.application.config.rails.approvals.reasons.prompt
        return if !reason_required && !reason_prompt

        prompt = TTY::Prompt.new
        response = prompt.multiline("Please enter a reason for running #{command}:", help: '(Press Ctrl+D or Ctrl+Z to submit)')

        self.reason = response.join("\n")
      end

      def publish_message_to_slack
        # The initial request has already been sent to Slack, we now need to
        # update it as the request state has changed.
        if slack_message_ts?
          Rails::Approvals.slack.chat_update(
            channel: slack_channel_id,
            ts: slack_message_ts,
            blocks: SlackMessage.new(self).as_json,
          )
        else
          message = Rails::Approvals.slack.chat_postMessage(
            channel: Rails.application.config.rails.approvals.slack.channel,
            blocks: SlackMessage.new(self).as_json,
          )

          update!(
            slack_message_ts: message.ts,
            slack_channel_id: message.channel,
          )
        end
      end
    end
  end
end
