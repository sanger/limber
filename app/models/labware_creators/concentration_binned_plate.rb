# frozen_string_literal: true

module LabwareCreators
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
  class ConcentrationBinnedPlate < StampedPlate
    include LabwareCreators::RequireWellsWithConcentrations

    validate :wells_with_aliquots_have_concentrations?

    # The binning configuration from the plate purpose.
    # This includes source volume, diluent volume and array of bins.
    # Each bin specifies the min/max amounts, number of PCR cycles and display colour.
    def binning_config
      purpose_config.fetch(:concentration_binning)
    end

    def bin_calculator
      @bin_calculator ||= Utility::ConcentrationBinningCalculator.new(binning_config)
    end

    private

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
      @transfer_hash ||= compute_well_transfers
    end

    def dest_well_qc_attributes
      @dest_well_qc_attributes ||=
        bin_calculator.construct_dest_qc_assay_attributes(child.uuid, 'Concentration Binning', transfer_hash)
    end

    def compute_well_transfers
      bin_calculator.compute_well_transfers(parent)
    end

    def after_transfer!
      Sequencescape::Api::V2::QcAssay.create(
        qc_results: dest_well_qc_attributes
      )
    end
  end
end
