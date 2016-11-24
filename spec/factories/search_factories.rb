
FactoryGirl.define do
  factory :search, class: Sequencescape::Search, traits: [:api_object] do
    json_root 'search'
    name "Find something"
    named_actions ["first", "last", "all"]
  end
end