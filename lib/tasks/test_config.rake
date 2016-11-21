namespace :test_config do
  task :generate do
    settings = {searches: {'Find something' => nil},
                transfer_templates: {'Transfer columns' => nil},
                purposes: {'purpose-uuid' => nil},
                request_types: {'Request_type' => nil},
                purpose_uuids: {'purpose' => 'uuid'},
                printers: {'limit' => 5, 'default_count' => 2},
                metadata_key_options: ['Key1', 'Key2', 'Key3', 'Key4'],
                label_templates:
                  {"1D Tube" => "sqsc_1dtube_label_template",
                    "96 Well Plate" => "sqsc_96plate_label_template",
                    "384 Well Plate" => "sqsc_384plate_label_template"}
              }
    File.open(File.join(Rails.root, %w{config settings}, "test.yml"), "w") {|f| f.write(settings.to_yaml)}
  end
end