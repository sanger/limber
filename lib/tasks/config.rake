#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.
namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  require "#{Rails.root}/config/robots.rb"

  PLATE_PURPOSES = [
    'ILB_STD_INPUT',
    'ILB_STD_COVARIS',
    'ILB_STD_SH',
    'ILB_STD_PCR',
    'ILB_STD_PCRR',
    'ILB_STD_PREPCR',
    'ILB_STD_PCRXP',
    'ILB_STD_PCRRXP',

    'Cherrypicked',
    'Shear',
    'Post Shear',
    'Post Shear XP',
    'AL Libs',
    'Lib PCR',
    'Lib PCRR',
    'Lib PCR-XP',
    'Lib PCRR-XP',

    'Lib Norm',
    'Lib Norm 2',
    'Lib Norm 2 Pool',

    ## Pulldown
    'ISCH lib pool',
    'ISCH hyb',
    'ISCH cap lib',
    'ISCH cap lib PCR',
    'ISCH cap lib PCR-XP',
    'ISCH cap lib pool',

    'PF Cherrypicked',
    'PF Shear',
    'PF Post Shear',
    'PF Post Shear XP',
    'PF AL Libs',
    'PF Lib XP',
    'PF Lib XP2',
    'PF EM Pool',
    'PF Lib Norm'

  ]

  QC_PLATE_PURPOSES = [
    'Post Shear QC',
    'Lib PCR-XP QC',
    'Lib PCRR-XP QC',
    'Lib Norm QC',

    'PF qPCR QC'
  ]

  TUBE_PURPOSES = [
    'ILB_STD_STOCK',
    'ILB_STD_MX',

    'Lib Pool',
    'Lib Pool Pippin',
    'Lib Pool Norm',
    'Lib Pool Conc',
    'Lib Pool SS',
    'Lib Pool SS-XP',
    'Lib Pool SS-XP-Norm',

    'Standard MX',
    'Cap Lib Pool Norm',

    'PF MiSeq Stock',
    'PF MiSeq QC'
  ]

  task :generate => :environment do
    api = Sequencescape::Api.new(IlluminaBPipeline::Application.config.api_connection_options)

    plate_purposes    = api.plate_purpose.all.select { |pp| PLATE_PURPOSES.include?(pp.name) }
    qc_plate_purposes = api.plate_purpose.all.select { |pp| QC_PLATE_PURPOSES.include?(pp.name) }
    tube_purposes     = api.tube_purpose.all.select  { |tp| TUBE_PURPOSES.include?(tp.name)  }

    barcode_printer_uuid = lambda do |printers|
      ->(printer_name){
        printers.detect { |prt| prt.name == printer_name}.try(:uuid) or
        raise "Printer #{printer_name}: not found!"
      }
    end.(api.barcode_printer.all)

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

      configuration[:printers] = {}.tap do |printers|
        printers[:plate_a] = barcode_printer_uuid.('g316bc')
        printers[:plate_b] = barcode_printer_uuid.('g311bc2')
        printers[:tube]    = barcode_printer_uuid.('g311bc1')
        printers['limit'] = 5
        printers['default_count'] = 2
      end

      configuration[:purposes] = {}.tap do |labware_purposes|
        # Setup a hash that will enable us to lookup the form, presenter, and state changing classes
        # based on the name of the plate purpose.  We can then use that to generate the information for
        # the mapping from UUID.
        #
        # The inner block is laid out so that the class names align, not so it's readable!
        name_to_details = Hash.new do |h,k|
          h[k] = {
            :form_class           => 'Forms::CreationForm',
            :presenter_class      => 'Presenters::StandardPresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :plate_a
          }
        end.tap do |presenters|
          # Illumina-B plates
          presenters['ILB_STD_INPUT'].merge!(
            :presenter_class => 'Presenters::StockPlatePresenter'
          )

          presenters['ILB_STD_SH'].merge!(
            :presenter_class     => 'Presenters::QcCompletablePresenter',
            :state_changer_class => 'StateChangers::QcCompletablePlateStateChanger'
          )

          presenters['ILB_STD_PREPCR'].merge!(
            :presenter_class => 'Presenters::PrePcrPlatePresenter'
          )

          presenters['ILB_STD_PCR'].merge!(
            :form_class      => 'Forms::TaggingForm',
            :presenter_class => 'Presenters::PcrPresenter',
            :tag_layout_templates => ["Illumina B vertical tagging","Illumina B tagging"]
          )

          presenters['ILB_STD_PCRR'].merge!(
            :form_class           => 'Forms::TaggingForm',
            :tag_layout_templates => ["Illumina B vertical tagging","Illumina B tagging"],
            :presenter_class      => 'Presenters::PcrPresenter',
            :default_printer_type => :plate_b
          )

          presenters['ILB_STD_PCRXP'].merge!(
            :presenter_class      => 'Presenters::PcrXpOldPresenter',
            :state_changer_class  => 'StateChangers::PlateToTubeStateChanger',
            :default_printer_type => :plate_b
          )

          presenters['ILB_STD_PCRRXP'].merge!(
            :presenter_class      => 'Presenters::PcrXpOldPresenter',
            :state_changer_class  => 'StateChangers::PlateToTubeStateChanger',
            :default_printer_type => :plate_a
          )

          presenters['ILB_STD_STOCK'].merge!(
            :form_class           => 'Forms::TubesForm',
            :presenter_class      => 'Presenters::QCTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          presenters['ILB_STD_MX'].merge!(
            :form_class           => 'Forms::TubesForm',
            :presenter_class      => 'Presenters::FinalTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          # New Illumina-B plates
          presenters['Cherrypicked'].merge!(
            :presenter_class => 'Presenters::StockPlatePresenter'
          )

          presenters['Shear'].merge!(
            :presenter_class => 'Presenters::StandardPresenter'
          )

          presenters['Post Shear'].merge!(
            :presenter_class     => 'Presenters::PostShearPlatePresenter',
            :locations_children  => {
              'illumina_a' => 'Post Shear XP',
              'illumina_b' => 'Post Shear XP'
            }
          )

          presenters['Post Shear XP'].merge!(
            :presenter_class         => 'Presenters::StandardPresenter'
          )

          presenters['AL Libs'].merge!(
            :presenter_class         => 'Presenters::AlLibsPlatePresenter'
          )

          presenters['Lib PCR'].merge!(
            :form_class      => 'Forms::TaggingForm',
            :tag_layout_templates => ["Illumina pipeline tagging"],
            :presenter_class => 'Presenters::PcrPresenter'
          )

          presenters['Lib PCRR'].merge!(
            :form_class           => 'Forms::TaggingForm',
            :presenter_class      => 'Presenters::PcrPresenter',
            :default_printer_type => :plate_b
          )

          presenters['Lib PCR-XP'].merge!(
            :presenter_class      => 'Presenters::PcrXpPresenter',
            :state_changer_class  => 'StateChangers::BranchingPlateToTubeStateChanger',
            :default_printer_type => :plate_b
          )


          presenters['Lib PCR-XP QC'].merge!(
            :presenter_class         => 'Presenters::QcPlatePresenter',
            :default_printer_type    => :plate_b
          )


          presenters['Lib PCRR-XP'].merge!(
            :presenter_class      => 'Presenters::PcrXpPresenter',
            :state_changer_class  => 'StateChangers::BranchingPlateToTubeStateChanger',
            :default_printer_type => :plate_b
          )

          presenters['Lib PCRR-XP QC'].merge!(
            :presenter_class     => 'Presenters::QcPlatePresenter',
            :default_printer_type => :plate_b
          )

          presenters['Lib Pool'].merge!(
            :form_class           => 'Forms::TubesForm',
            :presenter_class      => 'Presenters::QCTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          presenters['Lib Pool Pippin'].merge!(
            :form_class           => 'Forms::IntermediateTubesForm',
            :presenter_class      => 'Presenters::SimpleTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          presenters['Lib Pool Conc'].merge!(
            :form_class           => 'Forms::IntermediateTubesForm',
            :presenter_class      => 'Presenters::SimpleTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          presenters['Lib Pool SS'].merge!(
            :form_class           => 'Forms::IntermediateTubesForm',
            :presenter_class      => 'Presenters::SimpleTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          presenters['Lib Pool SS-XP'].merge!(
            :form_class           => 'Forms::IntermediateTubesForm',
            :presenter_class      => 'Presenters::QCTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_uuid => barcode_printer_uuid.('g311bc1'),
            :default_printer_type => :tube
          )

          presenters['Lib Pool Norm'].merge!(
            :form_class           => 'Forms::TubesForm',
            :presenter_class      => 'Presenters::FinalTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube,
            :from_purpose         => 'Lib Pool'
          )

          presenters['Lib Pool SS-XP-Norm'].merge!(
            :form_class           => 'Forms::TubesForm',
            :presenter_class      => 'Presenters::FinalTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube,
            :from_purpose         => 'Lib Pool Pippin'
          )

          presenters['Lib Norm'].merge!(
            :presenter_class => 'Presenters::QcCompletablePresenter',
            :state_changer_class => 'StateChangers::QcCompletablePlateStateChanger'
          )

          presenters['Lib Norm QC'].merge!(
            :presenter_class     => 'Presenters::QcPlatePresenter',
            :default_printer_type => :plate_b
          )

          presenters['Lib Norm 2'].merge!({})

          presenters['Lib Norm 2 Pool'].merge!(
            :presenter_class     => 'Presenters::EndPlatePresenter',
            :form_class           => 'Forms::PoolingRowToColumn'
          )

          presenters['Standard MX'].merge!(
            :form_class           => 'Forms::TubesForm',
            :presenter_class      => 'Presenters::FinalTubePresenter',
            :state_changer_class  => 'StateChangers::DefaultStateChanger',
            :default_printer_type => :tube
          )

          # ISCH plates
          presenters["ISCH lib pool"].merge!(
            :form_class => "Forms::MultiPlatePoolingForm",
            :presenter_class => "Presenters::MultiPlatePooledPresenter",
            :default_printer_type => :plate_b
          )

          presenters["ISCH hyb"].merge!(
            :form_class => "Forms::BaitingForm",
            :presenter_class => 'Presenters::FullFailablePresenter',
            :robot=>'nx8-pre-hyb-pool',
            :default_printer_type => :plate_b
          )

          presenters['ISCH cap lib'].merge!(
            :presenter_class => 'Presenters::FailablePresenter',
            :robot=>'bravo-cap-wash',
            :default_printer_type => :plate_b
          )

          presenters['ISCH cap lib PCR'].merge!(
            :presenter_class => 'Presenters::FailablePresenter',
            :robot=>'bravo-post-cap-pcr-setup',
            :default_printer_type => :plate_b
          )

          presenters['ISCH cap lib PCR-XP'].merge!(
            :presenter_class => 'Presenters::FailablePresenter',
            :robot=>'bravo-post-cap-pcr-cleanup',
            :default_printer_type => :plate_b
          )

          presenters["ISCH cap lib pool"].merge!(
            :form_class => "Forms::AutoPoolingForm",
            :presenter_class => "Presenters::FinalPooledPresenter",
            :state_changer_class => 'StateChangers::AutoPoolingStateChanger',
            :default_printer_type => :plate_b
          )

          presenters['PF Cherrypicked'].merge!({
            :presenter_class => 'Presenters::StockPlatePresenter'
          })

          presenters['PF Shear'].merge!({})
          presenters['PF Post Shear'].merge!({})
          presenters['PF Post Shear XP'].merge!({

          })
          presenters['PF AL Libs'].merge!({
            :form_class      => 'Forms::TaggingForm',
            :tag_layout_templates => ["NEXTflex-96 barcoded adapters tags in rows (first oligo: AACGTGAT)"]
          })
          presenters['PF Lib XP'].merge!({

          })
          presenters['PF Lib XP2'].merge!({
            :presenter_class => 'Presenters::QcCompletablePresenter',
            :default_printer_type => :plate_b
          })
          presenters['PF EM Pool'].merge!({
            :presenter_class => 'Presenters::QcCompletablePresenter',
            :default_printer_type => :plate_b
          })
          presenters['PF Lib Norm'].merge!({
            :default_printer_type => :plate_b
          })

          presenters['PF qPCR QC'].merge!({
            :presenter_class         => 'Presenters::QcPlatePresenter',
            :default_printer_type => :plate_b
          })

        end

        purpose_details_by_uuid = lambda { |labware_purposes, purpose|
          labware_purposes[purpose.uuid] = name_to_details[purpose.name].dup.merge(
            :name => purpose.name
          )
        }.curry.(labware_purposes)

        puts "Preparing plate purpose forms, presenters, and state changers ..."
        plate_purposes.each(&purpose_details_by_uuid)
        puts "Preparing QC plate purpose forms, presenters, and state changers ..."
        qc_plate_purposes.each(&purpose_details_by_uuid)

        puts "Preparing Tube purpose forms, presenters, and state changers ..."
        tube_purposes.each(&purpose_details_by_uuid)
      end


      configuration[:purpose_uuids] = {}.tap do |purpose_uuids|

        store_purpose_uuids = lambda { |purpose_uuids, purpose|
          purpose_uuids[purpose.name] = purpose.uuid
        }.curry.(purpose_uuids)

        tube_purposes.each(&store_purpose_uuids)
        plate_purposes.each(&store_purpose_uuids)
        qc_plate_purposes.each(&store_purpose_uuids)
      end

      configuration[:robots]      = ROBOT_CONFIG
      configuration[:locations]   = LOCATION_PIPELINES
      configuration[:qc_purposes] = QC_PLATE_PURPOSES

      configuration[:request_types] = {}.tap do |request_types|
        request_types['illumina_htp_library_creation']    = ['Lib Norm',false]
        request_types['illumina_a_isc']                   = ['ISCH lib pool', false]
        request_types['illumina_a_re_isc']                = ['ISCH lib pool', false]
      end

    end


    # Write out the current environment configuration file
    File.open(File.join(Rails.root, %w{config settings}, "#{Rails.env}.yml"), 'w') do |file|
      file.puts(CONFIG.to_yaml)
    end
  end

  task :default => :generate
end
