
FactoryGirl.define do
  factory :transfer_template, class: Sequencescape::TransferTemplate, traits: [:api_object] do
    json_root 'transfer_template'
    name "Test transfers"
    named_actions ["preview"]
    resource_actions ["read", "create"]
    transfers ({"A1"=>"A1", "B1"=>"B1"})
  end
end