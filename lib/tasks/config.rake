# frozen_string_literal: true

namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  require "#{Rails.root}/config/robots.rb"

  STOCK_PURPOSE = 'Limber Cherrypicked'
  PLATE_PURPOSES = [
    'Limber Shear',
    'Limber Post Shear',
    'Limber Post Shear XP',
    'Limber AL Libs',
    'Limber Lib PCR',
    'Limber Lib PCR-XP',
    'Limber Lib Pool',
    'Limber Hyb',
    'Limber Cap Lib',
    'Limber Cap Lib PCR',
    'Limber Cap Lib PCR-XP',
    'Limber Cap Lib Pool'
  ].freeze

  QC_PLATE_PURPOSES = [
    'Limber QC'
  ].freeze

  TUBE_PURPOSES = [
    'Limber Stock Tube',
    'Limber MX Tube'
  ].freeze

  QC_TUBE_PURPOSES = [
    'PF MiSeq Stock'
  ].freeze

  task generate: :environment do
    api = Sequencescape::Api.new(Limber::Application.config.api_connection_options)

    all_plate_purposes = Hash[api.plate_purpose.all.map { |pp| [pp.name, pp] }]

    all_plate_purposes[STOCK_PURPOSE] ||= api.plate_purpose.create!(name: STOCK_PURPOSE, stock_plate: true, cherrypickable_target: true)

    PLATE_PURPOSES.inject(all_plate_purposes[STOCK_PURPOSE].uuid) do |parent, name|
      all_plate_purposes[name] ||= api.plate_purpose.create!(name: name, stock_plate: false, cherrypickable_target: false, parents: [parent])
      all_plate_purposes[name].uuid
    end

    plate_purposes    = all_plate_purposes.values.select { |pp| PLATE_PURPOSES.include?(pp.name) || STOCK_PURPOSE == pp.name }
    qc_plate_purposes = all_plate_purposes.values.select { |pp| QC_PLATE_PURPOSES.include?(pp.name) }
    tube_purposes     = api.tube_purpose.all.select { |tp| TUBE_PURPOSES.include?(tp.name) }

    barcode_printer_uuid = lambda do |printers|
      lambda do |printer_name|
        printers.detect { |prt| prt.name == printer_name }.try(:uuid) ||
          raise("Printer #{printer_name}: not found!")
      end
    end.call(api.barcode_printer.all)

    # Build the configuration file based on the server we are connected to.
    CONFIG = {}.tap do |configuration|
      configuration[:large_insert_limit] = 250

      configuration[:searches] = {}.tap do |searches|
        puts 'Preparing searches ...'

        api.search.all.each do |search|
          searches[search.name] = search.uuid
        end
      end

      configuration[:transfer_templates] = {}.tap do |transfer_templates|
        puts 'Preparing transfer templates ...'

        api.transfer_template.all.each do |transfer_template|
          transfer_templates[transfer_template.name] = transfer_template.uuid
        end
      end

      configuration[:printers] = {}.tap do |printers|
        printers[:plate_a] = barcode_printer_uuid.call('g316bc')
        printers[:plate_b] = barcode_printer_uuid.call('g311bc2')
        printers[:tube]    = barcode_printer_uuid.call('g311bc1')
        printers['limit'] = 5
        printers['default_count'] = 2
      end

      configuration[:purposes] = {}.tap do |labware_purposes|
        # Setup a hash that will enable us to lookup the form, presenter, and state changing classes
        # based on the name of the plate purpose.  We can then use that to generate the information for
        # the mapping from UUID.
        #
        # The inner block is laid out so that the class names align, not so it's readable!
        name_to_details = Hash.new do |h, k|
          h[k] = {
            form_class: 'Forms::CreationForm',
            presenter_class: 'Presenters::StandardPresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :plate_a
          }
        end.tap do |presenters|
          # New Illumina-B plates
          presenters['Limber Cherrypicked'][:presenter_class] = 'Presenters::StockPlatePresenter'

          presenters['Limber Post Shear']
          presenters['Limber Post Shear XP']
          presenters['Limber AL Libs']

          presenters['Limber Lib PCR'].merge!(
            form_class: 'Forms::TaggingForm',
            tag_layout_templates: ['Illumina pipeline tagging', 'Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)'],
            presenter_class: 'Presenters::PcrPresenter'
          )

          presenters['Limber Lib PCRR'].merge!(
            form_class: 'Forms::TaggingForm',
            presenter_class: 'Presenters::PcrPresenter',
            default_printer_type: :plate_b
          )

          presenters['Limber Lib PCR-XP'].merge!(
            state_changer_class: 'StateChangers::BranchingPlateToTubeStateChanger',
            default_printer_type: :plate_b
          )

          presenters['Limber Lib Pool'].merge!(
            form_class: 'Forms::TubesForm',
            presenter_class: 'Presenters::QCTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube
          )

          presenters['Limber Lib Pool Pippin'].merge!(
            form_class: 'Forms::IntermediateTubesForm',
            presenter_class: 'Presenters::SimpleTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube
          )

          presenters['Limber Lib Pool Conc'].merge!(
            form_class: 'Forms::IntermediateTubesForm',
            presenter_class: 'Presenters::SimpleTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube
          )

          presenters['Limber Lib Pool SS'].merge!(
            form_class: 'Forms::IntermediateTubesForm',
            presenter_class: 'Presenters::SimpleTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube
          )

          presenters['Limber Lib Pool SS-XP'].merge!(
            form_class: 'Forms::IntermediateTubesForm',
            presenter_class: 'Presenters::QCTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_uuid: barcode_printer_uuid.call('g311bc1'),
            default_printer_type: :tube
          )

          presenters['Limber Lib Pool Norm'].merge!(
            form_class: 'Forms::TubesForm',
            presenter_class: 'Presenters::FinalTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube,
            from_purpose: 'Lib Pool'
          )

          presenters['Limber Lib Pool SS-XP-Norm'].merge!(
            form_class: 'Forms::TubesForm',
            presenter_class: 'Presenters::FinalTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube,
            from_purpose: 'Lib Pool Pippin'
          )

          presenters['Limber Lib Norm'].merge!(
            presenter_class: 'Presenters::QcCompletablePresenter',
            state_changer_class: 'StateChangers::QcCompletablePlateStateChanger',
            default_printer_type: :plate_b
          )

          presenters['Limber Lib Norm QC'].merge!(
            presenter_class: 'Presenters::QcPlatePresenter',
            default_printer_type: :plate_b
          )

          presenters['Limber Lib Norm 2'][:default_printer_type] = :plate_b

          presenters['Limber Lib Norm 2 Pool'].merge!(
            presenter_class: 'Presenters::EndPlatePresenter',
            form_class: 'Forms::PoolingRowToColumn',
            default_printer_type: :plate_b
          )

          presenters['Limber Standard MX'].merge!(
            form_class: 'Forms::TubesForm',
            presenter_class: 'Presenters::FinalTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube
          )

          # ISCH plates
          presenters['Limber lib pool'].merge!(
            form_class: 'Forms::MultiPlatePoolingForm',
            presenter_class: 'Presenters::MultiPlatePooledPresenter',
            default_printer_type: :plate_b
          )

          presenters['Limber hyb'].merge!(
            form_class: 'Forms::BaitingForm',
            presenter_class: 'Presenters::FullFailablePresenter',
            robot: 'nx8-pre-hyb-pool',
            default_printer_type: :plate_b
          )

          presenters['Limber cap lib'].merge!(
            presenter_class: 'Presenters::FailablePresenter',
            robot: 'bravo-cap-wash',
            default_printer_type: :plate_b
          )

          presenters['Limber cap lib PCR'].merge!(
            presenter_class: 'Presenters::FailablePresenter',
            robot: 'bravo-post-cap-pcr-setup',
            default_printer_type: :plate_b
          )

          presenters['Limber cap lib PCR-XP'].merge!(
            presenter_class: 'Presenters::FailablePresenter',
            robot: 'bravo-post-cap-pcr-cleanup',
            default_printer_type: :plate_b
          )

          presenters['Limber cap lib pool'].merge!(
            form_class: 'Forms::AutoPoolingForm',
            presenter_class: 'Presenters::FinalPooledPresenter',
            state_changer_class: 'StateChangers::AutoPoolingStateChanger',
            default_printer_type: :plate_b
          )
        end

        purpose_details_by_uuid = lambda do |labware_purposes, asset_type, purpose|
          labware_purposes[purpose.uuid] = name_to_details[purpose.name].dup.merge(
            name: purpose.name,
            asset_type: asset_type
          )
        end.curry.call(labware_purposes)

        puts 'Preparing plate purpose forms, presenters, and state changers ...'
        plate_purposes.each(&purpose_details_by_uuid.curry.call('plate'))
        puts 'Preparing QC plate purpose forms, presenters, and state changers ...'
        qc_plate_purposes.each(&purpose_details_by_uuid.curry.call('plate'))

        puts 'Preparing Tube purpose forms, presenters, and state changers ...'
        tube_purposes.each(&purpose_details_by_uuid.curry.call('tube'))
      end

      configuration[:purpose_uuids] = {}.tap do |purpose_uuids|
        store_purpose_uuids = lambda do |purpose_uuids, purpose|
          purpose_uuids[purpose.name] = purpose.uuid
        end.curry.call(purpose_uuids)

        tube_purposes.each(&store_purpose_uuids)
        plate_purposes.each(&store_purpose_uuids)
        qc_plate_purposes.each(&store_purpose_uuids)
      end

      configuration[:robots]      = ROBOT_CONFIG
      configuration[:qc_purposes] = QC_PLATE_PURPOSES + QC_TUBE_PURPOSES

      configuration[:submission_templates] = {}.tap do |submission_templates|
        puts 'Preparing submission templates...'
        submission_templates['miseq'] = api.order_template.all.detect { |ot| ot.name == Limber::Application.config.qc_submission_name }.uuid
      end

      puts 'Setting study...'
      configuration[:study] = Limber::Application.config.study_uuid ||
                              puts('No study specified, using first study') ||
                              api.study.first.uuid
      puts 'Setting project...'
      configuration[:project] = Limber::Application.config.project_uuid ||
                                puts('No project specified, using first project') ||
                                api.project.first.uuid

      configuration[:request_types] = {}.tap do |request_types|
        request_types['illumina_htp_library_creation']    = ['Lib Norm', false]
        request_types['illumina_a_isc']                   = ['ISCH lib pool', false]
        request_types['illumina_a_re_isc']                = ['ISCH lib pool', false]
      end
    end

    # Write out the current environment configuration file
    File.open(File.join(Rails.root, %w(config settings), "#{Rails.env}.yml"), 'w') do |file|
      file.puts(CONFIG.to_yaml)
    end
  end

  task default: :generate
end
