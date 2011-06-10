require 'factory_girl'
Dir[File.expand_path(File.join(File.dirname(__FILE__),'../','../','spec','factories','**','*.rb'))].each {|f| require f}

begin
  puts "creating sysadmin"
  org = Factory(:organization, :name => 'System Administration')
  admin = Factory(:sysadmin, :email => 'sysadmin@hrtapp.com', :organization => org)
rescue ActiveRecord::RecordInvalid => e
  puts e.message
  puts "   Do you already have an org 'System Administration' or user named 'admin'? "
else
  puts "=> sysadmin user: #{admin.name} created (org: #{admin.organization.name})"
end