# frozen_string_literal: true

# This is used as part of a take task, and will be run within a console.
# rubocop:disable Rails/Output
# rubocop:disable Metrics/ParameterLists

class PurposeConfig
  attr_reader :name, :options, :store, :api
  class_attribute :default_state_changer, :default_options

  self.default_state_changer = 'StateChangers::DefaultStateChanger'

  def self.load(name, options, store, api, submission_templates, label_templates)
    case options.fetch(:asset_type)
    when 'plate' then PurposeConfig::Plate.new(name, options, store, api, submission_templates, label_templates)
    when 'tube' then PurposeConfig::Tube.new(name, options, store, api, submission_templates, label_templates)
    else raise "Unknown purpose type #{options.fetch(:asset_type)} for #{name}"
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
    default_options[:printer_type] = default_printer_type_for(default_options[:printer])
    default_options[:pmb_template] = default_pmb_template_for(default_options[:printer])
  end

  def config
    {
      name: name,
      creator_class: default_options[:creator],
      presenter_class: default_options[:presenter],
      state_changer_class: default_state_changer,
      default_printer_type: default_options[:printer],
      submission: submission_options,
      label_class: print_option(:label_class),
      printer_type: print_option(:printer_type),
      pmb_template: print_option(:pmb_template)
    }.merge(@options)
  end

  def uuid
    store.fetch(name).uuid
  end

  class Tube < PurposeConfig
    self.default_options = {}.tap do |options|
      options[:printer] = :tube
      options[:presenter] = 'Presenters::SimpleTubePresenter'
      options[:creator] = 'LabwareCreators::TubeFromTube'
      options[:label_class] = 'Labels::TubeLabel'
    end

    def register!
      puts "Creating #{name}"
      api.tube_purpose.create!(
        name: name,
        target_type: options.fetch(:target),
        type: options.fetch(:type)
      )
    end
  end

  class Plate < PurposeConfig
    self.default_options = {}.tap do |options|
      options[:printer] = :plate_a
      options[:presenter] = 'Presenters::StandardPresenter'
      options[:creator] = 'LabwareCreators::StampedPlate'
      options[:label_class] = 'Labels::PlateLabel'
    end

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

  def parents
    @options.fetch(:parents, []).map { |parent_name| store.fetch(parent_name).uuid }
  end

  def print_option(option)
    @label_templates.fetch(@template_name.to_s, {}).fetch(option, default_options[option])
  end

  def default_printer_type_for(printer_type)
    @label_templates.fetch('default_printer_type_names').fetch(printer_type)
  end

  def default_pmb_template_for(printer_type)
    @label_templates.fetch('default_pmb_templates').fetch(printer_type)
  end
end
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Rails/Output
