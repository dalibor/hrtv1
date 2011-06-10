Factory.define :data_request, :class => DataRequest do |f|
  f.sequence(:title)  { |i| "Request title #{i}" }
  f.organization      { Factory.create(:organization) }
  f.start_date        { "2010-01-01" }
  f.end_date          { "2012-01-01" }
  f.due_date          { "2012-09-01" }
  f.service_levels    { true }
  f.budget            { true }
  f.spend             { true }
  f.budget_by_quarter { false }
end
