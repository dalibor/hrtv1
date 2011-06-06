
#redefine this here so the old migrations wont fail.
class Currency < ActiveRecord::Base
end

if (currency = Currency.find_by_symbol('USD'))
  currency.toUSD = 1
  currency.save!
end

if (currency = Currency.find_by_symbol('EUR'))
  currency.toUSD = 580.0 / 800
  currency.save!
end

if (currency = Currency.find_by_symbol('RWF'))
  currency.toUSD = 1.0 / 580
  currency.save!
end

