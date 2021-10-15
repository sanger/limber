# frozen_string_literal: true

# Helper methods for the Exports controller
module ExportsHelper
  def each_source_metadata_for_plate(plate)
    plate.wells_in_columns.each do |dest_well|
      dest_well.transfer_requests_as_target.each do |transfer_req|
        # NB. Making assumption here that name field on asset is for a plate well
        # and contains a plate barcode and well location e.g. DN12345678:A1
        src_well = transfer_req.source_asset
        name_array = src_well.name.split(':')
        yield name_array[0], name_array[1], dest_well if name_array.length == 2
      end
    end
  end

  def each_source_metadata_for_plate_with_compound_samples(plate)
    plate.wells_in_columns.each do |dest_well|
      Sequencescape::Api::V2::SampleCompoundComponent.where(target_asset_id: dest_well.id).each do |scomp|
        source_well = Sequencescape::Api::V2::Well.find(scomp.asset_id)[0]

        # NB. Making assumption here that name field on asset is for a plate well
        # and contains a plate barcode and well location e.g. DN12345678:A1
        name_array = source_well.name.split(':')
        yield name_array[0], name_array[1], dest_well if name_array.length == 2
      end
    end
  end
  
  #
  # Returns the sum total of all samples within a well, this includes breaking
  # down compound samples into the sum of their components
  #
  # @param well [Sequencescape::Api::V2::Well] The well to count samples in
  #
  # @return [Integer] The total number of component samples with it well
  #
  def component_samples_count_for(well)
    well.aliquots.sum(&:component_samples_count)
  end
end
