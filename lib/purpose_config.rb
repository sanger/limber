# frozen_string_literal: true

# This is used as part of a rake task, and will be run within a console.
# rubocop:disable Rails/Output

# Purpose config is used to translate the configuration options in the purposes/*.yml
# files into the serialized versions in the config/settings/*.yml
# It also handles the registration of new purposes within Sequencescape.
class PurposeConfig
  attr_reader :name, :options, :store

  class_attribute :default_state_changer, :default_options

  self.default_state_changer = 'StateChangers::PlateStateChanger'

  def self.load(name, options, store, submission_templates, label_template_config)
    case options.fetch(:asset_type)
    when 'plate'
      PurposeConfig::Plate.new(name, options, store, submission_templates, label_template_config)
    when 'tube'
      PurposeConfig::Tube.new(name, options, store, submission_templates, label_template_config)
    when 'tube_rack'
      PurposeConfig::TubeRack.new(name, options, store, submission_templates, label_template_config)
    else
      raise "Unknown purpose type #{options.fetch(:asset_type)} for #{name}"
    end
  end

  #
  # @param name [String] name of the purpose, from the keys from the purposes.yml file
  # @param options [Hash] values under the name key from the purposes.yml file
  # @param label_template_config [Hash] hash version of the label_template_config.yml file
  #
  def initialize(name, options, store, submission_templates, label_template_config)
    @name = name
    @options = options
    @submission = @options.delete(:submission)
    @store = store
    @submission_templates = submission_templates
    @label_templates = label_template_config.fetch('templates')
    @label_template_defaults = label_template_config.fetch('defaults_by_printer_type')
    @template_name = @options.delete(:label_template) || ''
  end

  def config
    {
      name: name,
      **default_options,
      state_changer_class: default_state_changer,
      submission: submission_options,
      label_class: label_template[:label_class],
      printer_type: label_template[:printer_type],
      pmb_template: label_template[:pmb_template],
      sprint_template: label_template[:sprint_template]
    }.merge(@options)
  end

  def uuid
    store.fetch(name).uuid
  end

  # The TubeRack class is a configuration class for defining the purpose and behavior of tube racks within the system.
  # It inherits from PurposeConfig and sets default options and state changers specific to tube racks.
  #
  # Attributes:
  # - default_state_changer: Specifies the state changer class to be used for tube racks.
  # - default_options: A hash containing default configuration options for tube racks, including:
  #   - presenter_class: The class responsible for presenting tube racks.
  #   - creator_class: The class responsible for creating tube racks from other labwares.
  #   - default_printer_type: The default printer type for tube racks.
  #   - label_class: The class responsible for label printing for tube racks.
  #   - file_links: An array for file links associated with tube racks.
  #
  # Methods:
  # - register!: Registers the tube rack purpose by creating a new TubeRackPurpose record via the Sequencescape API.
  #   It uses the name and options provided to create the record.
  #
  # Example:
  #   tube_rack = TubeRack.new(name: 'TR Stock 96', options: { target: 'TubeRack', type: 'TubeRack::Purpose' })
  #   tube_rack.register!
  #
  class TubeRack < PurposeConfig
    self.default_state_changer = 'StateChangers::TubeRackStateChanger'

    self.default_options = {
      presenter_class: 'Presenters::TubeRackPresenter',
      # NB. this will need to be a more generic creator in future
      creator_class: 'LabwareCreators::PlateSplitToTubeRacks',
      # NB. Tube racks have etched barcodes, so don't typically need labels printed.
      default_printer_type: :plate_a,
      label_class: 'Labels::PlateLabel',
      file_links: []
    }.freeze

    def register!
      puts "Creating #{name}"
      options_for_creation = {
        name: name,
        size: config.fetch(:size, 96),
        target_type: config.fetch(:target, 'TubeRack'),
        purpose_type: config.fetch(:type, 'TubeRack::Purpose')
      }
      Sequencescape::Api::V2::TubeRackPurpose.create!(options_for_creation)
    end
  end

  # The Tube class is a configuration class for defining the purpose and behavior of tubes within the system.
  # It inherits from PurposeConfig and sets default options and state changers specific to tubes.
  #
  # Attributes:
  # - default_state_changer: Specifies the state changer class to be used for tubes.
  # - default_options: A hash containing default configuration options for tubes, including:
  #   - default_printer_type: The default printer type for tubes.
  #   - presenter_class: The class responsible for presenting tubes.
  #   - creator_class: The class responsible for creating tubes from other tubes.
  #   - label_class: The class responsible for labeling tubes.
  #   - file_links: An array for file links associated with tubes.
  #
  # Methods:
  # - register!: Registers the tube purpose by creating a new TubePurpose record in the Sequencescape API.
  #   It uses the name and options provided to create the record.
  #
  # Example:
  #   tube = Tube.new(name: 'Sample Tube', options: { target: 'Tube', type: 'Sample' })
  #   tube.register!
  #
  class Tube < PurposeConfig
    self.default_state_changer = 'StateChangers::TubeStateChanger'

    self.default_options = {
      default_printer_type: :tube,
      presenter_class: 'Presenters::SimpleTubePresenter',
      creator_class: 'LabwareCreators::TubeFromTube',
      label_class: 'Labels::TubeLabel',
      file_links: []
    }.freeze

    def register!
      puts "Creating #{name}"
      options_for_creation = { name: name, target_type: @options.fetch(:target), purpose_type: @options.fetch(:type) }
      Sequencescape::Api::V2::TubePurpose.create!(options_for_creation)
    end
  end

  # The Plate class is a configuration class for defining the purpose and behavior of plates within the system.
  # It inherits from PurposeConfig and sets default options specific to plates.
  #
  # Attributes:
  # - default_options: A hash containing default configuration options for plates, including:
  #   - default_printer_type: The default printer type for plates.
  #   - presenter_class: The class responsible for presenting plates.
  #   - creator_class: The class responsible for creating plates from other labware.
  #   - label_class: The class responsible for labeling plates.
  #   - file_links: An array of hashes representing file links associated with plates, each containing:
  #     - name: The display name of the file link.
  #     - id: The identifier for the file link.
  #
  # Methods:
  # - register!: Registers the plate purpose by creating a new PlatePurpose record in the Sequencescape API.
  #   It uses the name and options provided to create the record.
  #
  # Example:
  #   plate = Plate.new(name: 'Sample Plate', options: { target: 'Plate', type: 'Sample' })
  #   plate.register!
  #
  class Plate < PurposeConfig
    self.default_options = {
      default_printer_type: :plate_a,
      presenter_class: 'Presenters::StandardPresenter',
      creator_class: 'LabwareCreators::StampedPlate',
      label_class: 'Labels::PlateLabel',
      file_links: [
        { name: 'Download Concentration (nM) CSV', id: 'concentrations_nm' },
        { name: 'Download Concentration (ng/ul) CSV', id: 'concentrations_ngul' }
      ]
    }.freeze

    # Registers plate purpose within Sequencescape.
    #
    # @return [Sequencescape::Api::V2::PlatePurpose] the registered plate purpose
    def register!
      puts "Creating #{name}"

      # Plate purpose is registered using the version 2 of the API. This
      # maintains the behaviour of version 1, but includes an addditional
      # asset_shape option if configured. It raises an error if the purpose
      # cannot be created.
      options_for_creation = {
        name: name,
        stock_plate: config.fetch(:stock_plate, false),
        cherrypickable_target: config.fetch(:cherrypickable_target, false),
        input_plate: config.fetch(:input_plate, false),
        size: config.fetch(:size, 96)
      }.merge(config.slice(:asset_shape))
      Sequencescape::Api::V2::PlatePurpose.create!(options_for_creation)
    end
  end

  private

  def submission_options
    return {} if @submission.nil?

    {
      request_options: @submission.fetch('request_options', {}),
      template_uuid: @submission_templates[@submission.fetch('template_name')]
    }
  end

  def label_template
    @label_templates.fetch(@template_name.to_s, default_label_template)
  end

  def default_label_template
    printer_type_key = default_options[:default_printer_type]
    {
      label_class: default_options[:label_class],
      printer_type: @label_template_defaults.fetch('printer_type_names').fetch(printer_type_key),
      pmb_template: @label_template_defaults.fetch('pmb_templates').fetch(printer_type_key),
      sprint_template: @label_template_defaults.fetch('sprint_templates').fetch(printer_type_key)
    }
  end
end
# rubocop:enable Rails/Output
