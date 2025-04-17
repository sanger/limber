# frozen_string_literal: true

module LabwareCreators
  # Copy of the ConcentrationBinnedPlate class creator but uses a stamp instead of
  # a partial stamp to allow mid-pipeline use of concentration binned plates.
  #
  # Handles the generation of a concentration binned plate.
  # For each well on the source plate we use the concentration entered via
  # QuantHub to decide which bin and therefore which well the sample will be
  # transferred to on the destination plate.
  # N.B. Concentrations uploaded to QuantHub and used in the binning config below
  # need to be in ng/ul (nanograms per microlitre).
  # The binning parameters are retrieved from the plate purpose configuration.
  # The volume multiplier is applied to the concentration to give the total amount
  # of DNA/RNA in the well.
  # Wells in the bins are applied to the destination by column.
  # If there is enough space on the destination each new bin will start in a new
  # column. Otherwise bins will run consecutively without gaps.
  # Colour and cycle information in the configuration is used by the plate
  # presenter to clearly display the bins and show keys.
  #
  # Eg.
  # source_volume: 10,
  # diluent_volume: 25,
  # bins: [
  #   {
  #     colour: 1,
  #     pcr_cycles: 16,
  #     max: 25
  #   },
  #   {
  #     colour: 2,
  #     pcr_cycles: 12,
  #     min: 25,
  #     max: 500
  #   },
  #   {
  #     colour: 3,
  #     pcr_cycles: 8,
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
  class ConcentrationBinnedFullPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations
    include LabwareCreators::GenerateQcResults

    validate :wells_with_aliquots_must_have_concentrations

    def dilutions_calculator
      @dilutions_calculator ||= Utility::ConcentrationBinningCalculator.new(dilutions_config)
    end

    private

    def request_hash(source_well, child_plate, additional_parameters)
      {
        source_asset: source_well.uuid,
        target_asset:
          child_plate
            .wells
            .detect { |child_well| child_well.location == transfer_hash[source_well.location]['dest_locn'] }
            &.uuid,
        volume: dilutions_calculator.source_volume.to_s
      }.merge(additional_parameters)
    end

    # Uses the calculator to generate the hash of transfers to be performed on the parent plate
    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent, well_filter.filtered_wells)
    end
  end
end
