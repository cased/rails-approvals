require 'rails/railtie'

module Rails
  module Approvals
    class Railtie < ::Rails::Railtie
      # :nocov:
      console do
        # We only want to start an approval request if it's enabled.
        next unless ::Rails.application.config.rails.approvals.enabled

        request = Rails::Approvals::Request.request
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
      end
    end
  end
end
