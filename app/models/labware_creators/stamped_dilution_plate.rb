# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

# TODO: Here, we need to find the parent well concentrations,
# read from the configurations the dilution factor,
# and then create the child plate with the diluted concentrations.
module LabwareCreators
  # Simply creates a new plate of the specified purpose and transfers material
  # across in a direct stamp. (ie. The location of a sample on the source plate
  # is the same as the location on the destination plate.)
  class StampedDilutionPlate < Base
    include SupportParent::PlateOnly
    self.default_transfer_template_name = 'Custom pooling'
    self.attributes += [{ filters: {} }]

    PLATE_INCLUDES =
      'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'

    validates_nested :well_filter

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PLATE_INCLUDES, uuid: parent_uuid)
    end

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    def labware_wells
      parent.wells
    end

    private

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    # Overriding the create_plate_with_standard_transfer! method for validation and
    # custom behaviour specific to dilution plates.
    def create_plate_with_standard_transfer!
      # Check if the parent plate has wells with concentrations
      # First. take the wells with samples
      parent.wells.each do |well|
        if well.aliquots.sample.present? && well.latest_concentration.nil?
          errors.add(:base, "Well #{well.location} on the parent plate does not have a concentration value.")
        end
      end
      super
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def compute_well_amounts(wells)
      dilution_factor = purpose_config['dilution_factor'] || 10
      dilution_factor = 10 if dilution_factor.zero?
      # sort on well coordinate to ensure wells are in plate column order
      wells
        .sort_by(&:coordinate)
        .each_with_object({}) do |well, well_amounts|
          next if well.aliquots.blank?

          # check for well concentration value present
          if well.latest_concentration.blank?
            errors.add(:base, "Well #{well.location} does not have a concentration, cannot calculate amount in well")
            next
          end

          # concentration recorded is per microlitre, divide by the dilution factor to get the diluted amount
          # in ng in well
          well_amounts[well.location] = well.latest_concentration.value.to_f / dilution_factor
        end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes(child_plate),
        user_uuid: user_uuid
      )
    end

    def build_transfer_hash(well_amounts)
      well_amounts.each_with_object({}) do |(well_locn, amount), transfers_hash|
        # Calculate the diluted concentration for the target well
        diluted_concentration = (amount / (purpose_config['dilution_factor'] || 10)).to_s
        transfers_hash[well_locn] = { 'dest_locn' => well_locn, 'dest_conc' => diluted_concentration }
      end
    end

    def transfer_request_attributes(child_plate)
      well_filter.filtered.map { |well, additional_parameters| request_hash(well, child_plate, additional_parameters) }
    end

    def request_hash(source_well, child_plate, additional_parameters)
      # Dilute the concentration of the source well and assign it to the target well
      {
        source_asset: source_well.uuid,
        target_asset:
          child_plate
            .wells
            .detect { |child_well| child_well.location == transfer_hash[source_well.location]['dest_locn'] }
            &.uuid
      }.merge(additional_parameters)
    end
  end
end
