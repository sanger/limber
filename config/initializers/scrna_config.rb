# frozen_string_literal: true

# This hash is used to store constants used in pooling and chip loading calculations for samples in the scRNA pipeline.
Rails.application.config.scrna_config = {
  # Maximum volume of a sample in microlitres
  maximum_sample_volume: 60.0,
  # Minimum volume of a sample in microlitres
  minimum_sample_volume: 5.0,
  # Minimum volume required for resuspension in microlitres
  minimum_resuspension_volume: 10.0,
  # Conversion factor from millilitres to microlitres
  millilitres_to_microlitres: 1_000.0,
  # Number of cells required for each sample going into the pool
  required_number_of_cells: 30_000,
  # Factor accounting for wastage of material when transferring between labware
  wastage_factor: 0.95238,
  # Desired concentration of cells per microlitre for chip loading
  desired_chip_loading_concentration: 2400,
  # Desired number of cells per well in the chip
  desired_number_of_cells_per_chip_well: 90_000,
  # Desired volume of the sample in microlitres
  desired_sample_volume: 37.5,
  # Volume taken for cell counting in microlitres
  volume_taken_for_cell_counting: 10.0,
  # Key for the required number of cells metadata stored on Study (in poly_metadata)
  study_required_number_of_cells_key: 'scrna_core_pbmc_donor_pooling_required_number_of_cells',
  # Default viability threshold for samples in percent
  viability_default_threshold: 65,
  # Default total cell count for samples
  total_cell_count_default_threshold: 50_000
}.freeze
