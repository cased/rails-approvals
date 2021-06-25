desc 'Add an approval processes to a Rake task'
task :require_approval do
  Rails::Approvals.start!
end
