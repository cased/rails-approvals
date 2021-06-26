module Rails
  module Approvals
    class SlackController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :verify_slack_request

      # Make sure to handle errors from request and return.
      unless Rails.env.development?
        rescue_from StandardError do |_exception|
          render json: {
            response_type: 'ephemeral',
            replace_original: false,
            text: "Sorry, that didn't work. Please try again.",
          }
        end
      end

      def create
        payload = JSON.parse(params[:payload])
        response = SlackResponse.new(payload)

        if response.perform
          head :ok
        else
          head :bad_request
        end
      end

      private

      def verify_slack_request
        return if valid_slack_request?

        head :unauthorized
      end

      def valid_slack_request?
        timestamp = request.headers['X-Slack-Request-Timestamp']

        # Prevent replay attacks by only processing requests from the last 5
        # minutes
        if Time.zone.at(timestamp.to_i) < 5.minutes.ago
          return false
        end

        signature = request.headers['X-Slack-Signature']
        basestring = ['v0', timestamp, request.body.read].join(':')
        signing_secret = Rails.application.config.rails.approvals.slack.signing_secret
        hd = OpenSSL::HMAC.hexdigest('SHA256', signing_secret, basestring)
        computed_signature = ['v0', hd].join('=')

        computed_signature == signature
      end
    end
  end
end
