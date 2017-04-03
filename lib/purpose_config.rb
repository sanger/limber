# frozen_string_literal: true

class PurposeConfig
  attr_reader :name, :options, :store, :api
  class_attribute :default_printer
  self.default_printer = :plate_a

  def self.load(name, options, store, api)
    case options.fetch(:asset_type)
    when 'plate' then PurposeConfig::Plate.new(name, options, store, api)
    when 'tube' then PurposeConfig::Tube.new(name, options, store, api)
    else raise "Unknown purpose type #{options.fetch(:asset_type)} for #{name}"
    end
  end

  def initialize(name, options, store, api)
    @name = name
    @options = options
    @store = store
    @api = api
  end

  def parents
    @options.fetch(:parents, []).map { |parent_name| store.fetch(parent_name).uuid }
  end

  def config
    {
      name: name,
      form_class: 'Forms::CreationForm',
      presenter_class: 'Presenters::StandardPresenter',
      state_changer_class: 'StateChangers::DefaultStateChanger',
      default_printer_type: default_printer
    }.merge(@options)
  end

  def uuid
    store.fetch(name).uuid
  end

  class Tube < PurposeConfig
    self.default_printer = :tube

    def register!
      api.tube_purpose.create!(
        name: name,
        parents: parents,
        target_type: options.fetch(:target),
        type: options.fetch(:type)
      )
    end
  end

  class Plate < PurposeConfig
    def register!
      api.plate_purpose.create!(
        name: name,
        stock_plate: config.fetch(:stock_plate, false),
        cherrypickable_target: config.fetch(:cherrypickable_target, false),
        input_plate: config.fetch(:input_plate, false),
        parents: parents
      )
    end
  end
end
