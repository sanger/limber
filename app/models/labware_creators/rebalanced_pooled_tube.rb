# frozen_string_literal: true

module LabwareCreators
  # RebalancedPooledTube is a labware creator used in the Ultima pipeline, responsible for
  # creating a rebalanced pooled tube based on user-provided rebalancing data from a
  #
  # In this pipeline, the user needs to create a rebalanced pooled tube (UPF Balanced Pool Tube)
  # based on the output of a previous sequencing run. The rebalancing is
  # calculated from a CSV file provided by the user, which contains the
  # rebalancing variables per sample/tag index.
  #
  # This class extends {PooledTubesBySubmission}, since in Ultima:
  # - pooling is always one tube per submission
  # - aliquots in the tube are the samples that were in the submission
  #   sequenced in the previous run
  #
  # Workflow:
  # 1. User uploads the previous run’s CSV file(downloaded from nexus platform).
  # 2. The CSV file is validated and parsed into rebalancing variables.
  # 3. For each aliquot in the rebalanced pooled tube, the calculated
  #    rebalancing variables are attached as poly_metadata.
  #
  # This will create the pooled tube and associate the calculated metadata
  # with its aliquots via the Sequencescape v2 API.
  #
  class RebalancedPooledTube < PooledTubesBySubmission
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateReadyForPoolingOnly

    self.page = 'rebalanced_pooled_tube'
    self.attributes += [:file]

    attr_accessor :file

    validates :file, presence: true
    validates_nested :csv_file, if: :file

    # Saves the pooled tube and attaches calculated poly_metadata to its aliquots.
    # @return [Boolean] true if the tube and poly_metadata were successfully saved
    def save
      super && save_calculated_metadata_to_tube_aliquots && true
    end

    # Iterates over the aliquots in the rebalanced pooled tube, looks up their
    # corresponding rebalancing variables, and builds a set of poly_metadata
    # to be created in bulk.
    #
    # @return [void]
    def save_calculated_metadata_to_tube_aliquots
      aliquot_poly_metadata = []
      rebalanced_pool_tube.aliquots.each do |aliquot|
        rebalancing_variables_for_aliquot = rebalancing_variables_per_tag_index[aliquot.tag_index.to_i - 1]
        next unless rebalancing_variables_for_aliquot

        rebalancing_variables_for_aliquot.each do |key, value|
          aliquot_poly_metadata << { key: key, value: value, metadatable: aliquot }
        end
      end
      create_aliquot_poly_metadata(aliquot_poly_metadata)
    end

    private

    def create_aliquot_poly_metadata(aliquot_poly_metadata)
      Sequencescape::Api::V2::PolyMetadatum.bulk_create(
        Sequencescape::Api::V2::PolyMetadatum.as_bulk_payload(aliquot_poly_metadata)
      )
    end

    def csv_file
      @csv_file ||= UltimaRebalancingCsvFile.new(file)
    end

    # Fetches the newly created pool tube (UPF Balanced Pool Tube) , including its aliquots.
    #
    # @return [Sequencescape::Api::V2::Tube]
    def rebalanced_pool_tube
      return @rebalanced_pool_tube if defined?(@rebalanced_pool_tube)

      @rebalanced_pool_tube = Sequencescape::Api::V2::Tube.find_by(uuid: @child_stock_tubes.values.first.uuid,
                                                                   includes: 'aliquots')
    end

    # Calculates the rebalancing variables and store them in hash map per tag index.
    #
    def rebalancing_variables_per_tag_index
      @rebalancing_variables_per_tag_index ||= @csv_file.calculate_rebalancing_variables
    end
  end
end
