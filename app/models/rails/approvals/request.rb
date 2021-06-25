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

      def prompt_for_requester
        return if requester?

        prompt = TTY::Prompt.new
        response = prompt.multiline("Who are you?", help: '(Press Ctrl+D or Ctrl+Z to submit)')

        self.requester = response.join("\n")
      end

      def prompt_for_reason
        return if reason?
        reason_required = ::Rails.application.config.rails.approvals.reasons.required
        reason_prompt = ::Rails.application.config.rails.approvals.reasons.prompt

        return if !reason_required && !reason_prompt

        prompt = TTY::Prompt.new
        response = prompt.multiline("Please enter a reason for running #{command}:", help: '(Press Ctrl+D or Ctrl+Z to submit)')

        self.reason = response.join("\n")
      end

      def publish_message_to_slack
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
