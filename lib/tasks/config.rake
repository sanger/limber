namespace :config do
  desc 'Generates a configuration file for the current Rails environment'
  task :generate => :environment do
    api = Sequencescape::Api.new(PulldownPipeline::Application.config.api_connection_options)

    # Build the configuration file based on the server we are connected to.
    configuration = {}

    configuration[:searches] = {}.tap do |searches|
      puts "Preparing searches ..."

      api.search.all.each do |search|
        searches[search.name] = search.uuid
      end
    end

    configuration[:transfer_templates] = {}.tap do |transfer_templates|
      puts "Preparing transfer templates ..."

      api.transfer_template.all.each do |transfer_template|
        transfer_templates[transfer_template.name] = transfer_template.uuid
      end
    end

    configuration[:plate_purposes] = {}.tap do |plate_purposes|
      # Setup a hash that will enable us to lookup the form, presenter, and state changing classes
      # based on the name of the plate purpose.  We can then use that to generate the information for
      # the mapping from UUID.
      #
      # The inner block is laid out so that the class names align, not so it's readable!
      name_to_details = Hash.new do |h,k|
        h[k] = {
          :form_class          => 'Forms::CreationForm',
          :presenter_class     => 'Presenters::StandardPresenter',
          :state_changer_class => 'StateChangers::DefaultStateChanger'
        }
      end.tap do |presenters|
        # WGS plates
        presenters["WGS stock plate"].merge!(                                                              :presenter_class => "Presenters::StockPlatePresenter")
        presenters["WGS library plate"].merge!(                 :form_class => "Forms::TransferForm")
        presenters["WGS library PCR plate"].merge!(             :form_class => "Forms::TaggingForm",       :presenter_class => "Presenters::TaggedPresenter")
        presenters["WGS pooled amplified library plate"].merge!(:form_class => "Forms::AutoPoolingForm",   :presenter_class => "Presenters::FinalPooledPresenter",  :state_changer_class => 'StateChangers::AutoPoolingStateChanger')

        # SC plates
        presenters["SC stock plate"].merge!(                                                               :presenter_class => "Presenters::StockPlatePresenter")
        presenters["SC library plate"].merge!(                  :form_class => "Forms::TransferForm")
        presenters["SC captured library PCR plate"].merge!(     :form_class => "Forms::TaggingForm",       :presenter_class => "Presenters::TaggedPresenter")
        presenters["SC hybridisation plate"].merge!(            :form_class => "Forms::BaitingForm",       :presenter_class => "Presenters::BaitedPresenter")
        presenters["SC pooled captured library plate"].merge!(  :form_class => "Forms::AutoPoolingForm",   :presenter_class => "Presenters::FinalPooledPresenter",  :state_changer_class => 'StateChangers::AutoPoolingStateChanger')

        # ISC plates
        presenters["ISC stock plate"].merge!(                                                              :presenter_class => "Presenters::StockPlatePresenter")
        presenters["ISC library plate"].merge!(                 :form_class => "Forms::TransferForm")
        presenters["ISC library PCR plate"].merge!(             :form_class => "Forms::TaggingForm",       :presenter_class => "Presenters::TaggedPresenter")
        presenters["ISC pooled amplified library plate"].merge!(:form_class => "Forms::CustomPoolingForm", :presenter_class => "Presenters::CustomPooledPresenter")
        presenters["ISC hybridisation plate"].merge!(           :form_class => "Forms::BaitingForm",       :presenter_class => "Presenters::BaitedPresenter")
        presenters["ISC pooled captured library plate"].merge!( :form_class => "Forms::AutoPoolingForm",   :presenter_class => "Presenters::FinalPooledPresenter",  :state_changer_class => 'StateChangers::AutoPoolingStateChanger')
      end

      puts "Preparing plate purpose forms, presenters, and state changers ..."

      api.plate_purpose.all.each do |plate_purpose|
        next unless plate_purpose.name == 'Pulldown QC plate' or plate_purpose.name =~ /^(WGS|SC|ISC)\s/ # Ignore unnecessary plates
        plate_purposes[plate_purpose.uuid] = name_to_details[plate_purpose.name].dup.merge(
          :name => plate_purpose.name
        )
      end
    end

    # Write out the current environment configuration file
    File.open(File.join(Rails.root, %w{config settings}, "#{Rails.env}.yml"), 'w') do |file|
      file.puts(configuration.to_yaml)
    end
  end

  task :default => :generate
end
