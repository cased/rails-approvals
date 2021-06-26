Rails::Approvals::Engine.routes.draw do
  post '/slack/webhook' => 'slack#create'
end
