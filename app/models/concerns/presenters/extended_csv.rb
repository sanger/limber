# frozen_string_literal: true

module Presenters::ExtendedCsv # rubocop:todo Style/Documentation
  extend ActiveSupport::Concern
  included do
    class_attribute :bed_prefix
    self.bed_prefix = 'PCRXP'
  end

  # Yields information for the show_extended.csv
  def each_well_transfer(offset = 0) # rubocop:todo Metrics/AbcSize
    index = 0
    transfers_for_csv[offset * 4...(offset + 1) * 4].each_with_index do |transfers_list, bed_index|
      transfers_list[:transfers].each do |transfer|
        source_well, destination_wells = transfer
        Array(destination_wells).each do |destination_well|
          yield({
            index: (index += 1),
            name: "#{bed_prefix}#{(offset * 4) + bed_index + 1}",
            source_well: source_well,
            destination_well: destination_well
          }.merge(transfers_list))
        end
      end
    end
  end

  private

  def all_wells
    return @all_wells unless @all_wells.nil?

    @all_wells = {}
    ('A'..'H').each { |r| (1..12).each { |c| @all_wells["#{r}#{c}"] = 'H12' } }
    @all_wells
  end

  # Split a location string into an array containing the row letter
  # and the column number (as a integer) so that they can be sorted.
  def split_location(location)
    match = location.match(/^([A-H])(\d+)/)
    [match[2].to_i, match[1]] # Order by column first
  end

  def legacy_labware
    api.plate.find(labware.uuid)
  end

  # rubocop:todo Metrics/MethodLength
  def transfers_for_csv # rubocop:todo Metrics/AbcSize
    legacy_labware.creation_transfers.map do |ct|
      source_ean = ct.source.barcode.ean13
      source_barcode = "#{ct.source.barcode.prefix}#{ct.source.barcode.number}"
      source_stock = "#{ct.source.stock_plate.barcode.prefix}#{ct.source.stock_plate.barcode.number}"
      destination_ean = ct.destination.barcode.ean13
      destination_barcode = "#{ct.destination.barcode.prefix}#{ct.destination.barcode.number}"
      transfers = ct.transfers.reverse_merge(all_wells).sort do |a, b|
        split_location(a.first) <=> split_location(b.first)
      end
      {
        source_ean: source_ean,
        source_barcode: source_barcode,
        source_stock: source_stock,
        destination_ean: destination_ean,
        destination_barcode: destination_barcode,
        transfers: transfers
      }
    end
  end
  # rubocop:enable Metrics/MethodLength
end
