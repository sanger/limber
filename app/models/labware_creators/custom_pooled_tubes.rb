# frozen_string_literal: true

require './lib/nested_validation'
module LabwareCreators
  # Allows the user to create custom pooled tubes.
  # THe user may create an arbitrary number of tubes, with a
  # 1 or more wells in each. An individual well may contribute
  # to more than one tube.
  class CustomPooledTubes < PooledTubesBase
    include LabwareCreators::CustomPage
    extend NestedValidation
    include SupportParent::PlateReadyForCustomPoolingOnly

    self.page = 'custom_pooled_tubes'
    self.attributes += [:file]

    delegate :pools, to: :csv_file

    validates :file, presence: true
    validates_nested :csv_file, if: :file
    validate :wells_occupied?

    def save!
      super # validates and creates tubes
      upload_file
    end

    def wells_occupied?
      pools.values.flatten.uniq.each do |location|
        well = well_locations[location]
        if well.nil? || well.aliquots.empty?
          errors.add(:csv_file, "includes empty well, #{location}")
        elsif well.pending?
          errors.add(:csv_file, "includes pending well, #{location}")
        end
      end
    end

    private

    # Our transfer requests don't include a submission id
    # as they don't have a submission
    def request_hash(source, target, _submission)
      {
        'source_asset' => source,
        'target_asset' => target
      }
    end

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
