# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of a plate with wells binned according to the number of
  # PCR cycles that has been determined by the customer.
  # Uploads a file supplied by the customer that has a row per each well and
  # includes Sample Volume, Diluent Volume, PCR Cycles, Sub-Pool and Coverage columns.
  # Uses the PCR Cycles column to determine the binning arrangement of the wells,
  # and the Sample Volume and Diluent Volume columns in the well transfers.
  # Sub-Pool and Coverage need to be stored for a later step downstream in the pipeline,
  # at the point where custom pooling is performed.
  # Wells in the bins are applied to the destination by column order.
  # If there is enough space on the destination plate each new bin will start in a new
  # column. Otherwise bins will run consecutively without gaps.
  #
  #
  # Source Plate                  Dest Plate
  # +--+--+--~                    +--+--+--~
  # |A1| pcr_cycles = 12 (bin 2)  |B1|A1|C1|
  # +--+--+--~                    +--+--+--~
  # |B1| pcr_cycles = 15 (bin 1)  |D1|E1|  |
  # +--+--+--~  +                 +--+--+--~
  # |C1| pcr_cycles = 10 (bin 3)  |  |G1|  |
  # +--+--+--~                    +--+--+--~
  # |D1| pcr_cycles = 15 (bin 1)  |  |  |  |
  # +--+--+--~                    +--+--+--~
  # |E1| pcr_cycles = 12 (bin 2)  |  |  |  |
  # +--+--+--~                    +--+--+--~
  # |G1| pcr_cycles = 12 (bin 2)  |  |  |  |
  class PcrCyclesBinnedPlate < PartialStampedPlate
    include LabwareCreators::CustomPage

    self.page = 'custom_pooled_tubes' # TODO: how does this work? new page for uploading file? see custom_pooled_tubes directory in labware_creators
    self.attributes += [:file]

    attr_accessor :file

    # delegate :pools, to: :csv_file # TODO: what is this doing? what does the file look like?

    validates :file, presence: true
    validates_nested :csv_file, if: :file # TODO: what does this do?
    validate :wells_have_required_information?

    def save
      super && upload_file && true
    end

    def wells_have_required_information?
      # pools.values.flatten.uniq.each do |location|
      #   well = well_locations[location]
      #   if well.nil? || well.aliquots.empty?
      #     errors.add(:csv_file, "includes empty well, #{location}")
      #   elsif well.pending?
      #     errors.add(:csv_file, "includes pending well, #{location}")
      #   end
      # end
    end

    def dilutions_calculator
      @dilutions_calculator ||= Utility::PcrCyclesBinningCalculator.new(dilutions_config)
    end


    private

    #
    # Upload the csv file onto the plate
    #
    def upload_file
      parent.qc_files.create_from_file!(file, 'robot_pooling_file.csv')
    end

    def csv_file
      @csv_file ||= CsvFile.new(file)
    end
  end
end
