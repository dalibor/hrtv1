# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require 'thread' #fixes uninitialized constant ActiveSupport::Dependencies::Mutex (NameError) on 2.3.8
require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

require 'rake/version_task'
Rake::VersionTask.new do |task|
  task.with_git_tag = true
end