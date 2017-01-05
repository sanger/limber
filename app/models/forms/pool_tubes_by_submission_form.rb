# frozen_string_literal: true
module Forms
  # Pools an entire plate into a single tube. Useful for MiSeqQC
  class PoolTubesBySubmissionForm < CreationForm
    attr_reader :tube_transfer

    def create_objects!
      true
    rescue
      false
    end

    def child
      tube_transfer.try(:destination) || :contents_not_transfered
    end
  end
end
