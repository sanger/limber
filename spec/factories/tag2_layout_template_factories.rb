# frozen_string_literal: true

FactoryBot.define do
  # API v1 Tag2 layout templates to handle the tag2 tubes. These have mostly been replaced
  # by UDI plates which contain both tags
  factory :tag2_layout_template, class: Sequencescape::Tag2LayoutTemplate, traits: [:api_object] do
    json_root { 'tag2_layout_template' }
    resource_actions { %w[read create] }

    name { 'Test tag2 layout' }

    tag { { 'name' => 'Tag', 'oligo' => 'AAA' } }
  end

  # A collection of tag2 layout templates, to support limber retrieving all registered templates
  factory :tag2_layout_template_collection, class: Sequencescape::Api::PageOfResults, traits: [:api_object] do
    size { 2 }

    transient do
      json_root { nil }
      resource_actions { %w[read first last] }
      resource_url { 'tag2_layout_templates/1' }
      uuid { nil }
    end

    tag2_layout_templates do
      Array.new(size) do |i|
        associated(:tag2_layout_template, uuid: "tag2-layout-template-#{i}", name: "Tag2 layout #{i}")
      end
    end
  end
end
