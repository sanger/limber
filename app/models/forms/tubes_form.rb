module Forms
  class TubesForm < CreationForm

    attr_reader :tube_transfer

    def create_objects!
      @tube_transfer = api.transfer_template.find(
        Settings.transfer_templates["Transfer from tube to tube by submission"]
      ).create!(
        :user   => user_uuid,
        :source => parent_uuid
      )
     true
    rescue => e
      false
    end

    # We pretend that we've added a new blank tube when we're actually
    # transfering to the tube on the original LibraryRequest
    def child
      tube_transfer.try(:destination) || :contents_not_transfered_to_mx_tube
    end

  end
end
