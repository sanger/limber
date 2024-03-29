# frozen_string_literal: true

namespace :test_config do
  task generate: :environment do
    settings = {
      searches: {
        'Find something' => nil
      },
      transfer_templates: {
        'Transfer columns' => nil
      },
      purposes: {
        'purpose-uuid' => nil
      },
      request_types: {
        'Request_type' => nil
      },
      purpose_uuids: {
        'purpose' => 'uuid'
      },
      printers: {
        'limit' => 5,
        'default_count' => 2
      },
      metadata_key_options: %w[Key1 Key2 Key3 Key4],
      label_templates: {
        'tube' => 'tube_label_template_1d',
        'plate' => 'sqsc_96plate_label_template'
      }
    }
    Rails.root.join('config/settings/test.yml').write(settings.to_yaml)
  end
end
