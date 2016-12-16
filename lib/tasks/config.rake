# frozen_string_literal: true

namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  require "#{Rails.root}/config/robots.rb"

  STOCK_PURPOSE = 'LB Cherrypick'
  PLATE_PURPOSES = [
    'LB Shear',
    'LB Post Shear',
    'LB End Prep',
    'LB AL Libs',
    'LB Lib PCR',
    'LB Lib PCR-XP'
  ].freeze
  TUBE_PURPOSES = [
    'LB Lib Pool',
    'LB Lib Pool Norm'
  ].freeze

  TUBE_PURPOSE_TARGET = {
    'LB Lib Pool' => 'StockMultiplexedLibraryTube',
    'LB Lib Pool Norm' => 'MultiplexedLibraryTube'
  }.freeze

  task generate: :environment do
    api = Sequencescape::Api.new(Limber::Application.config.api_connection_options)

    all_plate_purposes = Hash[api.plate_purpose.all.map { |pp| [pp.name, pp] }]

    all_plate_purposes[STOCK_PURPOSE] ||= api.plate_purpose.create!(name: STOCK_PURPOSE, stock_plate: true, cherrypickable_target: true, input_plate: true)

    last_purpose_uuid = PLATE_PURPOSES.inject(all_plate_purposes[STOCK_PURPOSE].uuid) do |parent, name|
      all_plate_purposes[name] ||= api.plate_purpose.create!(name: name, stock_plate: false, cherrypickable_target: false, parent_uuids: [parent])
      all_plate_purposes[name].uuid
    end

    all_tube_purposes = Hash[api.tube_purpose.all.map { |tp| [tp.name, tp] }]

    TUBE_PURPOSES.inject(last_purpose_uuid) do |parent, name|
      all_tube_purposes[name] ||= api.tube_purpose.create!(name: name, parent_uuids: [parent], target_type: TUBE_PURPOSE_TARGET[name])
      all_tube_purposes[name].uuid
    end

    plate_purposes    = all_plate_purposes.values.select { |pp| PLATE_PURPOSES.include?(pp.name) || STOCK_PURPOSE == pp.name }
    tube_purposes     = all_tube_purposes.values.select { |tp| TUBE_PURPOSES.include?(tp.name) }

    barcode_printer_uuid = lambda do |printers|
      lambda do |printer_name|
        # Update behaviour when we clean this up. At least output an error.
        printers.detect { |prt| prt.name == printer_name }.try(:uuid) || printers.first
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
          presenters['LB Cherrypick'][:presenter_class] = 'Presenters::StockPlatePresenter'
          presenters['LB Shear']
          presenters['LB Post Shear']
          presenters['LB End Prep']
          presenters['LB AL Libs']
          presenters['LB Lib PCR'].merge!(
            form_class: 'Forms::TaggingForm',
            tag_layout_templates: ['Illumina pipeline tagging', 'Sanger_168tags - 10 mer tags in columns ignoring pools (first oligo: ATCACGTT)'],
            presenter_class: 'Presenters::PcrPresenter'
          )
          presenters['LB Lib PCR-XP'].merge!(
            state_changer_class: 'StateChangers::BranchingPlateToTubeStateChanger',
            default_printer_type: :plate_b
          )

          presenters['LB Lib Pool'].merge!(
            form_class: 'Forms::TubesForm',
            presenter_class: 'Presenters::QCTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube
          )

          presenters['LB Lib Pool Norm'].merge!(
            form_class: 'Forms::TubesForm',
            presenter_class: 'Presenters::FinalTubePresenter',
            state_changer_class: 'StateChangers::DefaultStateChanger',
            default_printer_type: :tube,
            from_purpose: 'Lib Pool'
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

        puts 'Preparing Tube purpose forms, presenters, and state changers ...'
        tube_purposes.each(&purpose_details_by_uuid.curry.call('tube'))
      end

      configuration[:purpose_uuids] = {}.tap do |purpose_uuids|
        store_purpose_uuids = lambda do |purpose_uuids, purpose|
          purpose_uuids[purpose.name] = purpose.uuid
        end.curry.call(purpose_uuids)

        tube_purposes.each(&store_purpose_uuids)
        plate_purposes.each(&store_purpose_uuids)
      end

      configuration[:robots]      = ROBOT_CONFIG
      configuration[:qc_purposes] = []

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
