namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  PLATE_PURPOSES = [ 
    'ILB_STD_INPUT',
    'ILB_STD_COVARIS',
    'ILB_STD_SH',
    'ILB_STD_PCR',
    'ILB_STD_PCRR',
    'ILB_STD_PREPCR',
    'ILB_STD_PCRXP',
    'ILB_STD_PCRRXP'
  ]

  TUBE_PURPOSES = [
    'ILB_STD_STOCK',
    'ILB_STD_MX'
  ]

  task :generate => :environment do
    api = Sequencescape::Api.new(IlluminaBPipeline::Application.config.api_connection_options)

    plate_purposes = api.plate_purpose.all.select { |pp| PLATE_PURPOSES.include?(pp.name) }
    tube_purposes  = api.tube_purpose.all.select  { |tp| TUBE_PURPOSES.include?(tp.name)  }

    # Build the configuration file based on the server we are connected to.
    CONFIG = {}.tap do |configuration|

      configuration[:'large_insert_limit'] = 250

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

      configuration[:purposes] = {}.tap do |labware_purposes|
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
          # Illumina-B plates
          presenters['ILB_STD_INPUT'].merge!(
            :presenter_class => 'Presenters::StockPlatePresenter'
          )

          presenters['ILB_STD_SH'].merge!(
            :presenter_class => 'Presenters::QcCompletablePresenter',
            :state_changer_class => 'StateChangers::QcCompletablePlateStateChanger'
          )

          presenters['ILB_STD_PREPCR'].merge!(
            :presenter_class => 'Presenters::PrePcrPlatePresenter'
          )

          presenters['ILB_STD_PCR'].merge!(
            :form_class      => 'Forms::TaggingForm',
            :presenter_class => 'Presenters::PcrPresenter'
          )

          presenters['ILB_STD_PCRR'].merge!(
            :form_class      => 'Forms::TaggingForm',
            :presenter_class => 'Presenters::PcrPresenter'
          )

          presenters['ILB_STD_PCRXP'].merge!(
            :presenter_class     => 'Presenters::PcrXpPresenter',
            :state_changer_class => 'StateChangers::PlateToTubeStateChanger'
          )

          presenters['ILB_STD_PCRRXP'].merge!(
            :presenter_class     => 'Presenters::PcrXpPresenter',
            :state_changer_class => 'StateChangers::PlateToTubeStateChanger'
          )

          presenters['ILB_STD_STOCK'].merge!(
            :form_class          => 'Forms::TubeCreationForm',
            :presenter_class     => 'Presenters::TubePresenter',
            :state_changer_class => 'StateChangers::DefaultStateChanger'
          )

          presenters['ILB_STD_MX'].merge!(
            :form_class          => 'Forms::TubeCreationForm',
            :presenter_class     => 'Presenters::FinalTubePresenter',
            :state_changer_class => 'StateChangers::DefaultStateChanger'
          )

        end

        purpose_details_by_uuid = lambda { |labware_purposes, purpose|
          labware_purposes[purpose.uuid] = name_to_details[purpose.name].dup.merge(
            :name => purpose.name
          )
        }.curry.(labware_purposes)

        puts "Preparing plate purpose forms, presenters, and state changers ..."
        plate_purposes.each(&purpose_details_by_uuid)

        puts "Preparing Tube purpose forms, presenters, and state changers ..."
        tube_purposes.each(&purpose_details_by_uuid)
      end



      configuration[:purpose_uuids] = {}.tap do |purpose_uuids|

        store_purpose_uuids = lambda { |purpose_uuids, purpose|
          purpose_uuids[purpose.name] = purpose.uuid
        }.curry.(purpose_uuids)

        tube_purposes.each(&store_purpose_uuids)
        plate_purposes.each(&store_purpose_uuids)
      end

    end


    # Write out the current environment configuration file
    File.open(File.join(Rails.root, %w{config settings}, "#{Rails.env}.yml"), 'w') do |file|
      file.puts(CONFIG.to_yaml)
    end
  end

  task :default => :generate
end
