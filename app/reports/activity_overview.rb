require 'fastercsv'

class Reports::ActivityOverview
  include Reports::Helpers
  include CurrencyNumberHelper
  include CurrencyViewNumberHelper

  def initialize(request)
    @implementer_splits = ImplementerSplit.find :all,
      :joins => { :activity => :data_response },
      :conditions => ['data_responses.data_request_id = ? AND
                       data_responses.state = ?', request.id, 'accepted'],
      :include => [{ :activity => [{ :project => { :in_flows => :from } },
        { :data_response => :organization } ]},
        { :organization => :data_responses }]
  end

  def csv
    FasterCSV.generate do |csv|
      csv << build_header
      @implementer_splits.each do |implementer_split|
        csv << build_row(implementer_split)
      end
    end
  end

  private
    def build_header
      row = []

      row << 'Organization'
      row << 'Project'
      row << 'Activity'
      row << 'Activity ID'
      row << 'Activity URL'
      row << 'Funding Source'

      row << 'Implementer'
      row << 'Implementer Split ID'
      row << 'Expenditure ($)'
      row << 'Budget ($)'
      row << 'Possible Double-Count?'
      row << 'Actual Double-Count?'

      row
    end

    def build_row(implementer_split)
      activity = implementer_split.activity

      row = []

      row << activity.organization.name
      row << activity.project.try(:name) # other costs does not have a project
      row << activity.name
      row << activity.id
      row << activity_url(activity)
      row << project_in_flows(activity.project)
      row << implementer_split.organization.try(:name)
      row << implementer_split.id
      row << n2c(universal_currency_converter(implementer_split.spend, activity.currency, 'USD'))
      row << n2c(universal_currency_converter(implementer_split.budget, activity.currency, 'USD'))
      row << implementer_split.possible_double_count?
      # don't use double_count?, we need to display if the value is nil
      row << implementer_split.double_count

      row
    end

    def currencies
      if @currencies
        @currencies
      else
        @currencies = {}
        Currency.all.map{|c| @currencies[c.conversion] = c.rate }
        @currencies
      end
    end

    def activity_url(activity)
      "https://resourcetracking.heroku.com/responses/#{activity.data_response.id}/activities/#{activity.id}/edit"
    end
end
