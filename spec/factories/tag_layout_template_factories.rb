
# frozen_string_literal: true

FactoryBot.define do
  factory :tag_layout_template, class: Limber::TagLayoutTemplate, traits: [:api_object] do
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
        'tags' => (1..size).each_with_object({}) { |i, hash| hash[i.to_s] = i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
      }
    end

    factory :tag_layout_template_by_row do
      direction 'row'
    end

    factory :tag_layout_template_by_quadrant do
      walking_by 'quadrants'
      direction 'column then row'
    end

    factory :dual_index_tag_layout_template do
      tag2_group do
        {
          'name' => 'Tag group 2',
          'tags' => (1..size).each_with_object({}) { |i, hash| hash[i.to_s] = i.to_s(4).tr('0', 'A').tr('1', 'T').tr('2', 'C').tr('3', 'G') }
        }
      end
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
      direction 'column'
    end

    tag_layout_templates do
      Array.new(size) do |i|
        associated(template_factory, uuid: "tag-layout-template-#{i}", name: "Tag2 layout #{i}", direction: direction)
      end
    end

    factory :tag_layout_template_collection_by_row do
      transient do
        direction 'row'
        template_factory :tag_layout_template_by_row
      end
    end

    factory :tag_layout_template_collection_by_quadrant do
      transient do
        template_factory :tag_layout_template_by_quadrant
      end
    end
  end
end
