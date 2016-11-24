
FactoryGirl.define do
  factory :tag_layout_template, class: Sequencescape::TagLayoutTemplate, traits: [:api_object] do
    json_root 'tag_layout_template'

    direction "column"
    walking_by "wells in pools"

    name 'Test tag layout'

    tag_group do
      {
        "name" => "Tag group 1",
        "tags" => ({
          "1" => "ACTG",
          "2" => "GTCA"
        })
      }
    end

  end
end