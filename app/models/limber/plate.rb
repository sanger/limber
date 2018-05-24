# frozen_string_literal: true

#
# Class Limber::Plate provides a client side representation of Sequencescape plates
#
# @author Genome Research Ltd.
#
class Limber::Plate < Sequencescape::Plate
  # Customize the has_many association to use out custom class.
  has_many :transfers_to_tubes, class_name: 'Limber::TubeTransfer'

  delegate :number_of_pools, :pcr_cycles, :library_type_name, :insert_size, :ready_for_automatic_pooling?,
           :ready_for_custom_pooling?, :submissions, :primer_panel,
           to: :pools_info

  #
  # The width of the plate. Assumes a 4:3 ratio
  #
  # @return [Integer] Plate width in wells
  #
  def width
    Math.sqrt(size / 6).to_i * 3
  end

  #
  # The height of the plate. Assumes a 4:3 ratio
  #
  # @return [Integer] Plate height in wells
  #
  def height
    Math.sqrt(size / 6).to_i * 2
  end

  def pools_info
    @pools_info ||= Pools.new(pools)
  end

  def role
    label.prefix
  end

  def purpose
    plate_purpose
  end

  # We know that if there are any transfers with this plate as a source then they are into
  # tubes.
  def transfers_to_tubes?
    transfer_request_collections.present? || transfers_to_tubes.present?
  end

  def tubes
    tubes_and_sources.map(&:first)
  end

  def tagged?
    first_filled_well = wells.detect { |w| w.aliquots.first }
    first_filled_well && first_filled_well.aliquots.first.tag.identifier.present?
  end

  #
  # Returns an array consisting of the child tubes of a plate, and the wells
  # that were transferred into each.
  #
  # @return [Array<Array>] An array of arrays, tubes and their source wells.
  # eg. [[<Limber::Tube>, ['A1','B1']],[<Limber::Tube>,['C1','D1']]]
  #
  def tubes_and_sources
    @tubes_and_sources ||= generate_tubes_and_sources
  end

  def human_barcode
    "#{barcode.prefix}#{barcode.number}"
  end

  private

  def generate_tubes_and_sources
    return [] unless transfers_to_tubes?

    tube_hash = generate_tube_hash
    # Sort the source well list in column order
    tube_hash.transform_values! do |well_list|
      WellHelpers.sort_in_column_order(well_list)
    end
    # Sort the tubes in column order based on their first well
    tube_hash.sort_by { |_tube, well_list| WellHelpers.well_coordinate(well_list.first) }
  end

  def generate_tube_hash
    if transfer_request_collections.present?
      updated_tube_hash
    else
      legacy_tube_hash
    end
  end

  # Supports early plates. Uses plate_to_tube_transfers
  def legacy_tube_hash
    tube_hash = Hash.new { |h, i| h[i] = [] }
    # Build a list of all source wells for a given tube

    well_to_tube_transfers = transfers_to_tubes.reduce([]) do |all_transfers, transfer|
      all_transfers.concat(transfer.transfers.to_a)
    end

    well_to_tube_transfers.each do |well, tube|
      tube_hash[tube] << well
    end

    tube_hash
  end

  def updated_tube_hash
    tube_hash = Hash.new { |h, i| h[i] = [] }

    transfer_requests = []
    tube_indexes = {}

    transfer_request_collections.each do |trc|
      transfer_requests.concat(trc.transfer_requests.all)
      tube_indexes.merge!(trc.target_tubes.index_by(&:uuid))
    end

    transfer_requests.each do |tr|
      location = well_uuids_to_location.fetch(tr.source_asset.uuid)
      tube = tube_indexes[tr.target_asset.uuid]
      tube_hash[tube] << location if tube
    end

    tube_hash
  end

  def well_uuids_to_location
    @well_uuids_to_map_description ||= wells.each_with_object({}) do |well, hash|
      hash[well.uuid] = well.location
    end
  end
end
