Factory.define :organization, :class => Organization do |f|
  f.sequence(:name)                  { |i| "organization_name_#{i}_#{rand(100_000_000)}" }
  f.raw_type                         { "" }
  f.currency                         { "RWF" }
  f.fiscal_year_start_date           { "2008-09-01" }
  f.fiscal_year_end_date             { "2009-08-31" }
  f.contact_name                     { "Bob" }
  f.contact_position                 { "Manager" }
  f.contact_phone_number             { "123123123" }
  f.contact_main_office_phone_number {"234234234"}
  f.contact_office_location          { "Cape Town" }
end

Factory.define :provider, :class => Organization, :parent => :organization do |f|
end

Factory.define :donor, :class => Organization, :parent => :organization do |f|
end

Factory.define :ngo, :class => Organization, :parent => :organization do |f|
end

