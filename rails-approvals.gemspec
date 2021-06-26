require_relative "lib/rails/approvals/version"

Gem::Specification.new do |spec|
  spec.name        = "rails-approvals"
  spec.version     = Rails::Approvals::VERSION
  spec.authors     = ["Garrett Bjerkhoel"]
  spec.email       = ["me@garrettbjerkhoel.com"]
  spec.homepage    = "https://github.com/cased/rails-console-approval"
  spec.summary     = "Add an approval process to rails console in production."
  spec.description = "Add an approval process to rails console in production."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cased/rails-console-approval"
  spec.metadata["changelog_uri"] = "https://github.com/cased/rails-console-approval/tags"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 6.0.0"
  spec.add_dependency "slack-ruby-client", ">= 0.15.0"
  spec.add_dependency "tty-prompt", "~> 0.23.0"
end
