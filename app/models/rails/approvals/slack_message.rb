module Rails
  module Approvals
    class SlackMessage
      attr_reader :request

      def initialize(request)
        @request = request
      end

      def as_json
        metadata_fields = [].tap do |metadata|
          if request.reason?
            metadata << {
              type: 'mrkdwn',
              text: "*Reason:*\n#{request.reason}",
            }
          end
        end

        blocks = [
          {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: "*#{request.requester}* is requesting to run *#{request.command}*.",
            },
          },
        ]

        if metadata_fields.any?
          blocks << {
            type: 'section',
            fields: metadata_fields,
          }
        end

        blocks << {
          type: 'divider',
        }

        if request.requested?
          global_id = request.to_global_id
          blocks << {
            type: "actions",
            block_id: global_id.to_s,
            elements: [
              {
                type: "button",
                text: {
                  type: "plain_text",
                  emoji: true,
                  text: "Approve"
                },
                style: "primary",
                value: "approve"
              },
              {
                type: "button",
                text: {
                  type: "plain_text",
                  emoji: true,
                  text: "Deny"
                },
                style: "danger",
                value: "deny"
              }
            ]
          }
        elsif request.approved?
          blocks << {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: "✅ *#{request.responder}* has approved the session.",
            },
          }
        elsif request.denied?
          blocks << {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: "🛑 *#{request.responder}* has denied the session.",
            },
          }
        elsif request.canceled?
          blocks << {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: "Request was canceled by *#{request.requester}*.",
            },
          }
        elsif request.timed_out?
          blocks << {
            type: 'section',
            text: {
              type: 'mrkdwn',
              text: '🛑 Session timed out.',
            },
          }
        end

        blocks
      end
    end
  end
end
