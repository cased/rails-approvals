module Rails
  module Approvals
    class ApplicationRecord < ActiveRecord::Base
      self.abstract_class = true
    end
  end
end
