
# frozen_string_literal: true

FactoryBot.define do
  factory :tag_layout_template, class: Sequencescape::TagLayoutTemplate, traits: [:api_object] do
    json_root 'tag_layout_template'
    resource_actions %w[read create]

    direction 'column'
    walking_by 'wells of plate'

    transient do
      size 96
    end

    name 'Test tag layout'

    tag_group do
      {
        'name' => 'Tag group 1',
        'tags' => Hash[(1..size).map { |i| [i.to_s, i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G')] }]
      }
    end

    factory :tag_layout_template_by_row do
      direction 'row'
    end
  end

  factory :tag_layout_template_collection, class: Sequencescape::Api::Associations::HasMany::AssociationProxy, traits: [:api_object] do
    size 2

    transient do
      json_root nil
      resource_actions %w[read first last]
      resource_url { 'tag_layout_templates/1' }
      uuid nil
      template_factory :tag_layout_template
    end

    tag_layout_templates do
      Array.new(size) do |i|
        associated(template_factory, uuid: "tag-layout-template-#{i}", name: "Tag2 layout #{i}")
      end
    end

    factory :tag_layout_template_collection_by_row do
      transient do
        template_factory :tag_layout_template_by_row
      end
    end
  end
end
