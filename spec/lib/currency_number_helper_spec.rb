require 'spec_helper'
include CurrencyNumberHelper

describe CurrencyNumberHelper do
  before :each do
    Money.default_bank.set_rate(:EUR, :USD, 1.5)
    Money.default_bank.set_rate(:USD, :EUR, 0.720461095)
    Money.default_bank.set_rate(:GBP, :USD, 2)
    Money.default_bank.set_rate(:RWF, :KES, 5)
    Money.default_bank.set_rate(:AOA, :USD, nil)
    Money.default_bank.set_rate(:AOA, :EUR, nil)
  end

  it "should not change the amounts when the projects currency and the data_response currency are the same" do
    universal_currency_converter(1000, "EUR","EUR").should == 1000
  end

  it "should correctly convert currencies to USD then from USD to the currency when a direct conversion is not possible" do
    universal_currency_converter(1000, "GBP", "EUR").should == 1440.92219
  end

  it "should correctly convert currencies correctly when a direct conversion is possible" do
   universal_currency_converter(1000, "RWF", "KES").should == 5000
  end

  it "when a conversion to USD is not possible by one currency and one of the currencies is not USD" do
    universal_currency_converter(1000, "AOA", "USD").should == 1000
  end

  it "when a conversion to USD is not possible by one currency" do
    universal_currency_converter(1000, "AOA", "EUR").should == 1000
  end
end
