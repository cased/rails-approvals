module Rails
  module Approvals
    class SlackResponse
      attr_reader :payload
      attr_reader :responder

      def initialize(payload)
        @payload = payload
        @responder = payload['user']['username']
      end

      def perform
        payload['actions'].all? do |action|
          request = GlobalID::Locator.locate(action['block_id'])

          case action['value']
          when 'approve'
            request.update!(
              responder: responder,
              state: :approved,
            )
          when 'deny'
            request.update!(
              responder: responder,
              state: :denied,
            )
          end
        end
      end
    end
  end
end
