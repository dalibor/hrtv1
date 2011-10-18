# Be sure to restart your server when you modify this file

RAILS_GEM_VERSION = '2.3.12' unless defined? RAILS_GEM_VERSION

require 'thread' #fixes uninitialized constant ActiveSupport::Dependencies::Mutex (NameError) on 2.3.8
require File.join(File.dirname(__FILE__), 'boot')

puts "WARN: $HRT_COUNTRY not set, defaulting to Rwanda" unless ENV['HRT_COUNTRY']
puts "Loading #{ENV['HRT_COUNTRY'] || "Rwanda"} environment. (#{RAILS_ENV})"

Rails::Initializer.run do |config|
  config.time_zone = 'UTC'

  # tell rails to load files from all subfolders in app/models/
  #config.autoload_paths += Dir["#{RAILS_ROOT}/app/models/*"].find_all { |f| File.stat(f).directory? }
  config.autoload_paths += %W(
                          #{RAILS_ROOT}/app/charts
                          #{RAILS_ROOT}/app/reports
                          #{RAILS_ROOT}/app/observers
                          #{RAILS_ROOT}/lib/named_scopes
                        )
  config.autoload_paths += Dir["#{RAILS_ROOT}/app/models/**/**"]

  # Observers
  config.active_record.observers = :comment_observer

  # disable spoofing check
  # http://pivotallabs.com/users/jay/blog/articles/1216-standup-4-7-2010-disabling-rails-ip-spoofing-safeguard
  # PT: https://www.pivotaltracker.com/story/show/6509545
  config.action_controller.ip_spoofing_check = false
end

require 'array_extensions'
require 'version'

# SQLite does not have a TO_CHAR() method
# adding this workaround to support using sqlite (e.g. test environments)
adapter_name = ActiveRecord::Base.connection.adapter_name
if adapter_name == "SQLite" 
  #unfortunately sqlite doesnt support month names
  CURRENT_LOGIN_TO_CHAR = 'STRFTIME(\'%d %m %Y\', current_login_at)'
else
  CURRENT_LOGIN_TO_CHAR = 'TO_CHAR(current_login_at, \'DD Mon YYYY\')'
end
