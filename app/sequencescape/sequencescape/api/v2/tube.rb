# frozen_string_literal: true

# Tubes can be barcoded, but only have one receptacle for samples.
class Sequencescape::Api::V2::Tube < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasRequests
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasWorklineIdentifier

  DEFAULT_INCLUDES = [:purpose, 'aliquots.request.request_type'].freeze

  self.tube = true

  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :descendants, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_one :receptacle, class_name: 'Sequencescape::Api::V2::Receptacle'

  has_many :aliquots
  has_many :direct_submissions
  has_many :state_changes
  has_many :transfer_requests_as_target, class_name: 'Sequencescape::Api::V2::TransferRequest'

  property :created_at, type: :time
  property :updated_at, type: :time

  def self.find_by(params)
    options = params.dup
    includes = options.delete(:includes) || DEFAULT_INCLUDES
    Sequencescape::Api::V2::Tube.includes(*includes).find(**options).first
  end

  def self.find_all(params)
    options = params.dup
    includes = options.delete(:includes) || DEFAULT_INCLUDES
    paginate = options.delete(:paginate) || {}
    Sequencescape::Api::V2::Tube.includes(*includes).where(**options).paginate(paginate).all
  end

  # Dummied out for the moment. But no real reason not to add it to the API.
  # This is accessed through the Receptacle
  # TODO: allow this method and delegate it?
  def requests_as_source
    []
  end

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::Tube
  #
  def model_name
    ::ActiveModel::Name.new(Limber::Tube, false)
  end

  # Currently us the uuid as our main identifier, might switch to human barcode soon
  def to_param
    uuid
  end

  def stock_plate(purpose_names: SearchHelper.stock_plate_names)
    # this is an array not a collection so cant use order_by
    # max_by naturally sorts in ascending order
    @stock_plate ||= ancestors.where(purpose_name: purpose_names).max_by(&:id)
  end
end
