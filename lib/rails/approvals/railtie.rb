require 'rails/railtie'

module Rails
  module Approvals
    class Railtie < ::Rails::Railtie
      # :nocov:
      console do
        Rails::Approvals.start!
      end
    end
  end
end
