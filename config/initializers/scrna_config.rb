# frozen_string_literal: true

# Stores constants used in pooling and chip loading calculations for samples in the scRNA Core pipeline.
Rails.application.config.scrna_config = {
  # Maximum volume to take into the pools plate for each sample (in microlitres)
  maximum_sample_volume: 60.0,
  # Minimum volume to take into the pools plate for each sample (in microlitres)
  minimum_sample_volume: 5.0,
  # Minimum volume required for resuspension in microlitres
  minimum_resuspension_volume: 10.0,
  # Conversion factor from millilitres to microlitres
  millilitres_to_microlitres: 1_000.0,
  # Number of cells required for each sample going into the pool
  required_number_of_cells_per_sample_in_pool: 30_000,
  # Factor accounting for wastage of material when transferring between labware
  wastage_factor: lambda { |number_of_samples_in_pool|
    return 0.75 if number_of_samples_in_pool <= 13

    0.6
  },
  # Fixed wastage volume in microlitres
  wastage_volume: 5.0,
  # Desired concentration of cells per microlitre for chip loading
  desired_chip_loading_concentration: 2400,
  # Desired volume in the chip well (in microlitres)
  desired_chip_loading_volume: 37.5,
  # Volume taken for cell counting in microlitres
  volume_taken_for_cell_counting: 10.0,
  # Allowance table, keyed on numbers of samples with values for number of cells per chip well
  # with values dependent on the Allowance band
  allowance_table: {
    '2 pool attempts, 2 counts' => {
      5 => 26_250,
      6 => 37_500,
      7 => 48_750,
      8 => 60_000,
      9 => 71_250,
      10 => 82_500
    },
    '2 pool attempts, 1 count' => {
      5 => 38_250,
      6 => 49_500,
      7 => 60_750,
      8 => 72_000,
      9 => 83_250,
      10 => nil
    },
    '1 pool attempt, 2 counts' => {
      5 => 52_500,
      6 => 75_000,
      7 => nil,
      8 => nil,
      9 => nil,
      10 => nil
    },
    '1 pool attempt, 1 count' => {
      5 => 76_500,
      6 => nil,
      7 => nil,
      8 => nil,
      9 => nil,
      10 => nil
    }
  },
  # Default viability threshold when passing/failing samples (in percent)
  viability_default_threshold: 65,
  # Default total cell count threshold when passing/failing samples
  total_cell_count_default_threshold: 50_000,
  # Key for the number of cells per chip well metadata stored on pool wells (in poly_metadata)
  number_of_cells_per_chip_well_key: 'scrna_core_pbmc_donor_pooling_number_of_cells_per_chip_well',
  # Valid number of samples in a pool (inclusive range), when pooling PBMCs in the cDNA prep stage
  valid_pool_size_range: (5..25),
  # Valid total number of pools (inclusive range), when pooling PBMCs in the cDNA prep stage
  valid_pool_count_range: (1..8)
}.freeze
