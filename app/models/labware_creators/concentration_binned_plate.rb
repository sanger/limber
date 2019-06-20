# frozen_string_literal: true

# Handle the generation of a concentration binned plate.
# For each well on the source plate we use the concentration entered via
# QuantHub to decide which bin and therefore which well the sample will be
# transferred to on the destination plate.
# The binning parameters are retrieved from the plate purpose configuration.
# The volume multiplier is applied to the concentration to give the total amount
# of DNA/RNA in the well.
# Wells in the bins are applied to the destination by column.
# If there is enough space on the destination each new bin will start in a new
# column. Otherwise bins will run concurrently.
# Colour and cycle information in the configuration is used by the plate
# presenter to clearly display the bins and show keys.
#
# Eg.
# source_volume: 10,
# diluent_volume: 25,
# bins: [
#   {
#     colour: 1,
#     cycles: 16,
#     max: 25
#   },
#   {
#     colour: 2,
#     cycles: 12,
#     min: 25,
#     max: 500
#   },
#   {
#     colour: 3,
#     cycles: 8,
#     min: 500
#   }
# ]
#
# Source Plate                     Dest Plate
# +--+--+--~                       +--+--+--~
# |A1| conc=4.3   x10=43  (bin 2)  |B1|A1|C1|
# +--+--+--~                       +--+--+--~
# |B1| conc=1.2   x10=12  (bin 1)  |D1|E1|  |
# +--+--+--~  +                    +--+--+--~
# |C1| conc=67.2  x10=672 (bin 3)  |  |G1|  |
# +--+--+--~                       +--+--+--~
# |D1| conc=2.1   x10=21  (bin 1)  |  |  |  |
# +--+--+--~                       +--+--+--~
# |E1| conc=33.7  x10=337 (bin 2)  |  |  |  |
# +--+--+--~                       +--+--+--~
# |G1| conc=25.9  x10=259 (bin 2)  |  |  |  |

module LabwareCreators
  class ConcentrationBinnedPlate < StampedPlate
    include LabwareCreators::ConcentrationBinning
    # TODO: include module to calculate bins from well concentrations and passed plate config
    # Must pass in the plate size to use in the modulus calc for if the bins are overfilling the plate
    # Test for a 384 plate as well as a 96

    validate :wells_with_aliquots_have_concentrations?
    validate :binning_configuration_valid?

    def parent_with_concs
      @parent_with_concs ||= Sequencescape::Api::V2.plate_with_custom_includes('wells.qc_results', parent_uuid)
    end

    def wells_with_aliquots_have_concentrations?
      concs_missing = []
      parent_with_concs.wells.each do |well|
        next if well.aliquots.blank?
        # if well does not have a concentration flag error
        puts "DEBUG: well at #{well.location} concentration = #{well.latest_concentration}"
        binding.pry
        errors.add(:parent, "Well at #{well.location} does not have a concentration") if well.latest_concentration.nil?
      end
    end

    def binning_configuration_valid?
      errors.add(:parent, 'Binning configuration not found for this plate type') if binning_config.blank?
      errors.add(:parent, 'Source volume not found within binning configuration') if binning_config['source_volume'].blank?
      errors.add(:parent, 'Diluent volume not found within binning configuration') if binning_config['diluent_volume'].blank?
      errors.add(:parent, 'Bin specifications not found within binning configuration') if binning_config['bins'].blank?
      # TODO: throw an exception??
    end

    # TODO: include write concentrations for destination wells (amount / source vol + diluent vol e.g. 35)

    #
    # The binning configuration from the plate purpose.
    # This includes source volume, diluent volume and array of bins.
    # Each bin specifies the min/max amounts, number of PCR cycles and display colour.
    #
    # @return [Hash] A hash containing the configuration details.
    #
    def binning_config
      purpose_config.fetch(:concentration_binning, {})
    end

    private

    # TODO: remove?
    # def transfer_request_attributes(child_plate)
    #   well_filter.filtered.map do |well, additional_parameters|
    #     request_hash(well, child_plate, additional_parameters)
    #   end
    # end

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => binning_config['source_volume']
      }.merge(additional_parameters)
    end

    def transfer_hash
      amnts = well_amounts(parent_with_concs, source_plate_multiplication_factor(binning_config))
      compute_transfers(amnts, binning_config, parent_with_concs.number_of_rows, parent_with_concs.number_of_columns)
    end

    def after_transfer!
      # perform concentration writing for destination here
      # write a qc_assay via endpoint for plate of well concentrations
      # set assay_type to 'calculated' or similar to indicate not direct
    end

    # Maps well locations to the corresponding uuid
    #
    # @return [Hash] Hash with well locations (eg. 'A1') as keys, and uuids as values
    # def well_locations
    #   @well_locations ||= parent.wells.index_by(&:location)
    # end
  end
end
