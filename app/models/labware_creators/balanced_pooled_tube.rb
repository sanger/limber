# frozen_string_literal: true

module LabwareCreators
  # BalancedPooledTube is a labware creator used in the Ultima pipeline, responsible for
  # Creating a balanced pooled tube based on user-provided balancing data from the outcome
  # of a previous sequencing run (CSV file downloaded from the Nexus platform)
  #
  # In this pipeline, the user needs to create a balanced pooled tube (UPF Balanced Pool Tube)
  # based on the output of a previous sequencing run. The balancing is
  # calculated from a CSV file provided by the user, which contains the
  # balancing variables per sample/tag index.
  #
  # This class extends {PooledTubesFromWholePlates}, using the transfer template {Whole plate to tube}.
  # In the Ultima pipeline:
  # - pooling always produces a single tube containing material from all wells of one XP2 plate
  # - aliquots in the tube are the samples that were in the submission
  #   sequenced in the previous run
  #
  # Workflow:
  # 1. User uploads the previous run’s CSV file(downloaded from nexus platform).
  # 2. The CSV file is validated and parsed into balancing variables.
  # 3. For each aliquot in the balanced pooled tube, the calculated
  #    balancing variables are attached as poly_metadata.
  class BalancedPooledTube < PooledTubesFromWholePlates
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateReadyForPoolingOnly

    self.page = 'balanced_pooled_tube'
    self.attributes += [:file]

    attr_accessor :file

    validates :file, presence: true
    validates_nested :csv_file, if: :file

    # Overrides PooledTubesFromWholePlates#parents=
    # In Ultima, the parent is always known from the context, so this assigns it directly.
    def parents
      @parents ||= [parent]
    end

    # Overrides PooledTubesFromWholePlates#barcodes=
    # In Ultima, the parent is always known from the context, so this assigns its barcode directly.
    def barcodes=(_input)
      @barcodes << parent.barcode
    end

    # Overrides PooledTubesFromWholePlates#parents_suitable
    # Always returns true, since the parent labware is known from context and does not
    # require user-entered validation (unlike the default behaviour).
    def parents_suitable
      true
    end

    # @return [Boolean] true if the tube and poly_metadata were successfully saved
    def save
      super && save_calculated_metadata_to_tube_aliquots && true
    end

    # Iterates over the aliquots in the balanced pooled tube, looks up their
    # corresponding balancing variables, and builds a set of poly_metadata
    # to be created in bulk.
    # This method relies on tag_index to match samples with those in the CSV file.
    # This approach is fragile if the tag_index values do not align with the CSV data.
    # A story exists to improve this (@todo Y25-585).
    # @return [void]
    def save_calculated_metadata_to_tube_aliquots
      aliquot_poly_metadata = []
      balanced_pool_tube.aliquots.each do |aliquot|
        balancing_variables_for_aliquot = balancing_variables_per_tag_index[aliquot.tag_index.to_i - 1]
        next unless balancing_variables_for_aliquot

        balancing_variables_for_aliquot.each do |key, value|
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
      @csv_file ||= UltimaBalancingCsvFile.new(file)
    end

    # Fetches the newly created pool tube (UPF Balanced Pool Tube) , including its aliquots.
    #
    # @return [Sequencescape::Api::V2::Tube]
    def balanced_pool_tube
      return @balanced_pool_tube if defined?(@balanced_pool_tube)

      @balanced_pool_tube = Sequencescape::Api::V2::Tube.find_by(uuid: @child.uuid,
                                                                 includes: 'aliquots')
    end

    # Calculates the balancing variables and store them in hash map per tag index.
    #
    def balancing_variables_per_tag_index
      @balancing_variables_per_tag_index ||= @csv_file.calculate_balancing_variables
    end
  end
end
