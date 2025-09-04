# frozen_string_literal: true

module LabwareCreators
  # Allows the user to create custom pooled tubes.
  # The user may create an arbitrary number of tubes, with
  # 1 or more wells in each. An individual well may contribute
  # to more than one tube.
  # Layout is specified by uploading the same CSV which will be used to
  # drive the robot.
  class CustomPooledTubes < PooledTubesBase
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateReadyForCustomPoolingOnly

    self.page = 'custom_pooled_tubes'
    self.attributes += [:file]

    attr_accessor :file

    delegate :pools, to: :csv_file

    validates :file, presence: true
    validates_nested :csv_file, if: :file
    validate :wells_occupied?

    def save
      super && upload_file && true
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
      { source_asset: source, target_asset: target }
    end

    #
    # Upload the csv file onto the plate
    #
    def upload_file
      Sequencescape::Api::V2::QcFile.create_for_labware!(
        contents: file.read,
        filename: 'robot_pooling_file.csv',
        labware: parent
      )
    end

    def csv_file
      @csv_file ||= CsvFile.new(file)
    end
  end
end
