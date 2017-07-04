# frozen_string_literal: true

module LabwareCreators
  # Allows the user to create custom pooled tubes.
  # THe user may create an arbitrary number of tubes, with a
  # 1 or more wells in each. An individual well may contribute
  # to more than one tube.
  class CustomPooledTubes < PooledTubesBase
    extend SupportParent::TaggedPlateOnly
    include Form::CustomPage

    self.page = 'custom_pooled_tubes'
    self.attributes += [:file]

    delegate :pools, to: :csv_file

    validates :file, presence: true
    validate :csv_file_valid?, if: :file

    def save!
      super # validates and creates tubes
      upload_file
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

    def csv_file_valid?
      return true if csv_file.valid?
      errors.add(:file, csv_file.errors.full_messages.join('; '))
      false
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
