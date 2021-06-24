Rails.application.routes.draw do
  mount Rails::Approvals::Engine => "/rails-approvals"
end
