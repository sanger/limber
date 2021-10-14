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

  def _each_source_metadata_for_plate_with_compound_samples(plate)
    raise 'Only one parent plate should be defined for a plate with compound samples' if plate.parents.count > 1
    parent_plate = Sequencescape::Api::V2::Plate.find_by(uuid: plate.parents.first.uuid)
    plate.wells_in_columns.each do |dest_well|
      raise 'Only one sample should be present in a destination with compound samples' if dest_well.samples.count > 1
      compound_sample = dest_well.samples.first
      next unless compound_sample
      compound_sample.component_samples.each do |component_sample|
        source_wells = parent_plate.wells.select{|w| w.samples.map(&:id).include?(component_sample.id)}
        raise 'Only one source well should be present in a destination with compound samples' if source_wells.count > 1
        source_well = source_wells.first
        # NB. Making assumption here that name field on asset is for a plate well
        # and contains a plate barcode and well location e.g. DN12345678:A1
        name_array = source_well.name.split(':')
        yield name_array[0], name_array[1], dest_well if name_array.length == 2
      end
    end
  end

end
