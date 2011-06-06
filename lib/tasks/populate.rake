namespace :db do
  desc "Loads initial database models for the current environment."
  task :populate => :environment do
    puts "Populating environment #{RAILS_ENV}"
    Dir[File.join(RAILS_ROOT, 'db', 'fixtures', '*.rb')].sort.each { |fixture| puts "Loading #{fixture}\n"; load fixture }
    Dir[File.join(RAILS_ROOT, 'db', 'fixtures', RAILS_ENV, '*.rb')].sort.each { |fixture| "Loading #{fixture}\n"; load fixture }
  end

  # this fixture file no long exists
  #task :populate_users => :environment do
  #  puts "Populating users in environment #{RAILS_ENV}"
  #  load File.join(RAILS_ROOT, 'db', 'fixtures', '04_users.rb')
  #end

end
