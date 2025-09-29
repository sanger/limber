# frozen_string_literal: true

#
# This file defines the RebalancingCalculator class, which is responsible for
# computing pooling metrics used to generate the drive file for rebalanced pooled
# tubes in the Ultima pipeline. The calculator takes sample and sequencing data
# extracted from a rebalancing CSV file (e.g., barcodes, PF barcode reads,
# coverage values, and batch ID) and derives key metrics required for a second pooling.
module LabwareCreators
  require_dependency 'labware_creators/rebalanced_pooled_tube'

  # RebalancingCalculator is responsible for calculating pooling metrics for aliquots
  # to generate the drive file used for pooling rebalanced pooled tubes in the Ultima pipeline.
  #
  # It takes sample data extracted from the rebalancing CSV file and computes metrics such as:
  # - Coverage needed for wafers 2 & 3
  # - Expected coverage for wafers
  # - Pooling correction factor
  # - Volume to pool per sample
  #
  # The results are returned as a hash keyed by the aliquot index.
  class RebalancedPooledTube::RebalancingCalculator
    attr_reader :samples, :barcodes, :pf_barcode_reads, :mean_cvg, :batch_id

    # Initializes the calculator with the necessary data from the CSV file.
    #
    # @param samples [Array<String>] List of sample identifiers
    # @param barcodes [Array<String>] Corresponding barcodes for each sample
    # @param pf_barcode_reads [Array<Float>] PF barcode read counts
    # @param mean_cvg [Array<Float>] Mean coverage values for each sample
    # @param batch_id [String] Batch identifier parsed from the file name
    def initialize(samples, barcodes, pf_barcode_reads, mean_cvg, batch_id)
      @samples = samples
      @barcodes = barcodes
      @pf_barcode_reads = pf_barcode_reads
      @mean_cvg = mean_cvg
      @batch_id = batch_id
    end

    # Performs the full calculation for all samples and returns a hash of metrics keyed by sample index.
    #
    # @return [Hash{Integer => Hash}] Mapping of sample index to calculated metrics
    # @example [ 1 => { sample: 'S1', barcode: 'Z0001', pf_barcode_reads: 1500000, mean_cvg: 50.0,
    # 'CovNeed Waf2&3': 100.0, 'PoolCF Waf2&3': 1.0, 'ExpCov Waf2': 50.0, 'Average Cov Waf1': 75.0,
    # 'Vol to pool': 10.0, batch_id: '12345' }, ... ]
    def calculate
      @samples.map.with_index do |sample, index|
        [
          index, # key linked to tag_index, - 1 in the aliquot when creating the rebalanced pooled tube
          {
            sample: sample,
            barcode: @barcodes[index],
            pf_barcode_reads: @pf_barcode_reads[index],
            mean_cvg: @mean_cvg[index],
            'CovNeed Waf2&3': cov_need_waf2_and_waf3(index),
            'PoolCF Waf2&3': pool_cf_waf2_waf3(index),
            'ExpCov Waf2': exp_cov_waf2_waf3(index),
            'Average Cov Waf1': average_cov_waf1,
            'Vol to pool': vol_to_pool(index),
            batch_id: @batch_id
          }
        ]
      end.to_h
    end

    # Calculates the average coverage for wafer 1 across all samples.
    #
    # @return [Float] Average coverage value
    def average_cov_waf1
      (@mean_cvg.sum / @mean_cvg.length).round(4)
    end

    # Calculates the coverage needed for wafers 2 & 3 for a given sample.
    #
    # @param sample_index [Integer] Index of the sample
    # @return [Float] Coverage needed
    def cov_need_waf2_and_waf3(sample_index)
      ((3 * average_cov_waf1) - @mean_cvg[sample_index]).round(4)
    end

    # Calculates the expected coverage for wafers 2 & 3 for a given sample.
    #
    # @param sample_index [Integer] Index of the sample
    # @return [Float] Expected coverage
    def exp_cov_waf2_waf3(sample_index)
      (cov_need_waf2_and_waf3(sample_index) / 2).round(4)
    end

    # Calculates the pooling correction factor for wafers 2 & 3.
    #
    # @param sample_index [Integer] Index of the sample
    # @return [Float] Pooling correction factor
    def pool_cf_waf2_waf3(sample_index)
      (exp_cov_waf2_waf3(sample_index) / @mean_cvg[sample_index]).round(4)
    end

    # Calculates the volume to pool for a given sample based on the pooling correction factor.
    #
    # @param sample_index [Integer] Index of the sample
    # @return [Float] Volume to pool
    def vol_to_pool(sample_index)
      (pool_cf_waf2_waf3(sample_index) * 10).round(4)
    end
  end
end
