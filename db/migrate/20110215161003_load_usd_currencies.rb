class Currency < ActiveRecord::Base; end
class LoadUsdCurrencies < ActiveRecord::Migration
  def self.up
    if Rails.env != "test" && Rails.env != "cucumber"
      load 'db/fixes/20110215_load_usd_currencies.rb'
    end
  end

  def self.down
  end
end
