## For Developers

* Google Group: http://groups.google.com/group/rwandaonrails

* Pivotal Tracker: http://www.pivotaltracker.com/projects/59773

  * Its public - so click the "Join Project" button.

* Pairing/Mentoring
  * Let Greg know if you're available to do some pairing/mentoring! Mega bonus points.
  * More info on collaborating with local Rwandan team can be got by emailing gregory_nelson@abtassoc.com.

* GitHub: github.com/rwandaonrails/resource_tracking/

### RVM & Bundler

We use RVM+Bundler to standardize the Ruby and Gem environments across developers and to help new devs get up and running quickly.

  * install RVM if not already installed, see http://rvm.beginrescueend.com/rvm/install/ . Google / ask Greg if you have trouble.

  * Set your RVM ruby version

        $ rvm install ruby-1.8.7-p299
        $ rvm use ruby-1.8.7-p299

  * Create a "resource_tracking_non_ree" rvm gemset

        $ rvm gemset create 'resource_tracking_non_ree'

  * Install bundler for this gemset

        $ gem install --no-rdoc --no-ri bundler

  * Bundler go!

        $ bundle install

Note: if you have an error with database gem you won't be using, you can ignore it.

Note: if you have an error in forms like "{{attribute}} {{message}}" manually uninstall the "i18n" gem (it is installed as a dependency of formtastic gem and used in Rails 3)


### Local Setup

Database:

  cp config/database.yml.sample config/database.yml

Edit config/datbase.yml per your environment.  This file is not tracked by git.

  rake db:schema:load

  rake db:populate

  rake db:seed

### App settings

We keep sensitive env-specific settings in config/settings.secret.yml, which is not in the repo.

Either ask another developer for their settings.secret.yml, or simply create it using the example file;

  $ cp config/settings.secret.example.yml config/settings.secret.yml


### Feature Dev

Setup test DB

  rake db:create RAILS_ENV=test
  rake db:schema:load RAILS_ENV=test

Tests/TDD - before every commit, and after every fetch, is your friend.

  $ rake test

Develop on a local feature branch (as per: http://reinh.com/blog/2009/03/02/a-git-workflow-for-agile-teams.html). Let Greg / the mailing list know if you have any questions.

#### Git

See doc/GIT_WORKFLOW.rdoc

### Deploying

Sensitive settings is not in the repo and therefore not deployed to Heroku by default. Rather in
  config/settings.secret.yml

Without this file, to deploy, we must
  a) autogenerate a script containing the config variables
  b) load them into the Heroku environment.

The heroku:vars rake task does this automagically. First you generate the script from the "secret" settings yml;

  $ APP_NAME=rt-staging  rake heroku:vars:setup

Then using this autogenerated script, you load the config vars up into your heroku environment;

  $ rake heroku:vars:load

(this script is just a bunch of "heroku config:add key=val" commands). You can verify your config with;

  $ heroku config

    RACK_ENV         => staging
    SITE_DESCRIPTION => Health Resource Tracking & Planning
    SITE_NAME        => Resource Tracker