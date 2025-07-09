# frozen_string_literal: true

# A labware from sequencescape via the V2 API
class Sequencescape::Api::V2::Labware < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasQcFiles

  def self.table_name
    'labware'
  end

  property :created_at, type: :time
  property :updated_at, type: :time

  has_one :custom_metadatum_collection

  has_many :state_changes
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class

  def self.find_all(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::Labware.includes(*includes).where(options).all
  end

  #
  # Plates and tubes are handled by different URLs. This allows us to redirect
  # to the expected endpoint.
  # @return [ActiveModel::Name] The resource behaves like a a Plate, Tube, or TubeRack
  #
  def model_name
    case type
    when 'tubes'
      ::ActiveModel::Name.new(Tube, false)
    when 'plates'
      ::ActiveModel::Name.new(Plate, false)
    when 'tube_racks'
      ::ActiveModel::Name.new(TubeRack, false)
    else
      raise "Can't view #{type} in limber"
    end
  end

  # Currently use the uuid as our main identifier, might switch to human barcode soon
  def to_param
    uuid
  end

  def plate?
    type == 'plates'
  end

  def tube?
    type == 'tubes'
  end

  def tube_rack?
    type == 'tube_racks'
  end

  # ===== stock plate / input plate barcode ======

  def input_barcode
    stock_plate.try(:barcode).try(:human)
  end

  def stock_plate
    @stock_plate ||= find_stock_plate
  end

  # 'ancestors' returns different types based on the query used to retrieve 'self'
  # if ancestors was 'included' in the query, you get an Array
  # if not, you get a JsonApiClient::Query::Builder
  # sometimes you can also get nil
  # this method has no test - mocking was a nightmare and didn't represent real API responses
  def find_stock_plate
    stocks = SearchHelper.stock_plate_names
    return self if stock_plate?(purpose_names: stocks)

    if ancestors.instance_of?(Array)
      ancestors.select { |a| stocks.include? a.purpose.name }.max_by(&:id)
    elsif ancestors.instance_of?(JsonApiClient::Query::Builder)
      ancestors.where(purpose_name: stocks).order(id: :asc).last
    end
  end

  def stock_plate?(purpose_names: SearchHelper.stock_plate_names)
    purpose_names.include?(purpose.name)
  end

  # ===== end stock plate / input plate barcode ======
end
