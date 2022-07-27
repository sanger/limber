# frozen_string_literal: true

# This is used as part of a take task, and will be run within a console.
# rubocop:disable Rails/Output
# rubocop:disable Metrics/ParameterLists

# Purpose config is used to translate the configuration options in the purposes/*.yml
# files into the serialized versions in the config/settings/*.yml
# It also handles the registration of new purposes within Sequencescape.
class PurposeConfig
  attr_reader :name, :options, :store, :api

  class_attribute :default_state_changer, :default_options

  self.default_state_changer = 'StateChangers::DefaultStateChanger'

  def self.load(name, options, store, api, submission_templates, label_templates)
    case options.fetch(:asset_type)
    when 'plate'
      PurposeConfig::Plate.new(name, options, store, api, submission_templates, label_templates)
    when 'tube'
      PurposeConfig::Tube.new(name, options, store, api, submission_templates, label_templates)
    when 'tube_rack'
      PurposeConfig::TubeRack.new(name, options, store, api, submission_templates, label_templates)
    else
      raise "Unknown purpose type #{options.fetch(:asset_type)} for #{name}"
    end
  end

  def initialize(name, options, store, api, submission_templates, label_templates)
    @name = name
    @options = options
    @submission = options.delete(:submission)
    @store = store
    @api = api
    @submission_templates = submission_templates
    @label_templates = label_templates
    @template_name = (@options.delete(:label_template) || '')
  end

  def config
    {
      name: name,
      **default_options,
      state_changer_class: default_state_changer,
      submission: submission_options,
      label_class: print_option(:label_class),
      printer_type: print_option(:printer_type),
      pmb_template: print_option(:pmb_template)
    }.merge(@options)
  end

  def uuid
    store.fetch(name).uuid
  end

  # Currently limber does not register its own tube racks. This is because we
  # will delegate most behaviour to the contained tube purposes
  class TubeRack < PurposeConfig
    self.default_options = { default_printer_type: :tube_rack, presenter_class: 'Presenters::TubeRackPresenter' }.freeze

    def register!
      warn 'Cannot create tube racks from within limber'
    end
  end

  class Tube < PurposeConfig # rubocop:todo Style/Documentation
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
      api.tube_purpose.create!(name: name, target_type: options.fetch(:target), type: options.fetch(:type))
    end
  end

  class Plate < PurposeConfig # rubocop:todo Style/Documentation
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

    def register!
      puts "Creating #{name}"
      api.plate_purpose.create!(
        name: name,
        stock_plate: config.fetch(:stock_plate, false),
        cherrypickable_target: config.fetch(:cherrypickable_target, false),
        input_plate: config.fetch(:input_plate, false),
        size: config.fetch(:size, 96)
      )
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

  def default_printer_options
    {
      printer_type: default_printer_type,
      pmb_template: default_pmb_template,
      label_class: default_options[:label_class]
    }
  end

  def print_option(option)
    @label_templates.fetch(@template_name.to_s, {}).fetch(option, default_printer_options[option])
  end

  def default_printer_type
    @label_templates.fetch('default_printer_type_names').fetch(default_options[:default_printer_type])
  end

  def default_pmb_template
    @label_templates.fetch('default_pmb_templates').fetch(default_options[:default_printer_type])
  end
end
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Rails/Output
