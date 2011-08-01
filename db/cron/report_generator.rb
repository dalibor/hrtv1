#!/usr/bin/env ruby

# Daily report cron
#
# Regenerates long running report csv's
#
# == Usage
#   report_generator.rb <HEROKU_APP> <REPORT_RAKE_TASK>
#
# == Options
#   HEROKU_APP        name of the app to run the reports rake task on.
#   REPORT_RAKE_TASK  either 'fast', 'slow', 'all' etc (see reports.rake)
#
# == Notes
# Be sure to set the cron to run during quiet periods (overnight).
#  E.g.
#    Fast reports, 1am daily, except sunday
#      0 0 * * 1-6 report_generator.rb resourcetracking fast
#
#    All reports (including slow ones), 12am Sundays
#      0 0 * * 0 report_generator.rb resourcetracking all
#

require File.join(File.dirname(__FILE__), '../../lib/', 'script_helper')

include ScriptHelper

args       = ARGV.join(' ')
HEROKU_APP = ARGV[0] || DEFAULT_PRODUCTION_APP
RAKE_TASK  = ARGV[1] || 'fast'

date = get_date()

puts "\n\n*** #{date}: Report regeneration for #{HEROKU_APP} started... ***"

run "heroku rake reports:#{RAKE_TASK} --app #{HEROKU_APP}"

date = get_date()
puts "*** #{date}: Report regeneration done.\n\n"