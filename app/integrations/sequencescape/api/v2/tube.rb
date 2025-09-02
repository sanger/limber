# frozen_string_literal: true

# Tubes can be barcoded, but only have one receptacle for samples.
class Sequencescape::Api::V2::Tube < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasRequests
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasWorklineIdentifier
  include Sequencescape::Api::V2::Shared::HasQcFiles

  DEFAULT_INCLUDES = [
    :purpose,
    'receptacle.aliquots.request.request_type',
    'receptacle.requests_as_source.request_type'
  ].freeze

  self.tube = true

  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :child_plates, class_name: 'Sequencescape::Api::V2::Plate'
  has_many :child_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_one :receptacle, class_name: 'Sequencescape::Api::V2::Receptacle'

  has_many :direct_submissions
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :state_changes
  has_many :transfer_requests_as_target, class_name: 'Sequencescape::Api::V2::TransferRequest'

  has_one :custom_metadatum_collection

  has_one :racked_tube, class_name: 'Sequencescape::Api::V2::RackedTube'
  has_one :tube_rack, through: :racked_tube, class_name: 'Sequencescape::Api::V2::TubeRack'

  property :created_at, type: :time
  property :updated_at, type: :time

  def aliquots
    receptacle&.aliquots
  end

  def self.find_by(params)
    options = params.dup
    includes = options.delete(:includes) || DEFAULT_INCLUDES
    Sequencescape::Api::V2::Tube.includes(*includes).find(**options).first
  end

  def self.find_all(options, includes: DEFAULT_INCLUDES, paginate: {})
    Sequencescape::Api::V2::Tube.includes(*includes).where(**options).paginate(paginate).all
  end

  delegate :requests_as_source, to: :receptacle

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Tube
  #
  def model_name
    ::ActiveModel::Name.new(Tube, false)
  end

  # Overrides the Rails method to return the UUID of the labware for use in URL generation.
  #
  # @return [String] The UUID of the labware instance.
  def to_param
    # Currently use the uuid as our main identifier, might switch to human barcode soon
    uuid
  end

  def stock_plate(purpose_names: SearchHelper.stock_plate_names)
    # this is an array not a collection so cant use order_by
    # max_by naturally sorts in ascending order
    @stock_plate ||= ancestors.where(purpose_name: purpose_names).max_by(&:id)
  end
end
