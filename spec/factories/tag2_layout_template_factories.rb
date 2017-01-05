
# frozen_string_literal: true
FactoryGirl.define do
  factory :tag2_layout_template, class: Sequencescape::Tag2LayoutTemplate, traits: [:api_object] do
    json_root 'tag2_layout_template'

    name 'Test tag2 layout'

    tag do
      {
        'name' => 'Tag',
        'oligo' => 'AAA'
      }
    end
  end
end
