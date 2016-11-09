# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2013 Genome Research Ltd.
module Forms
  class IntermediateTubesForm < CreationForm
    attr_reader :tube_transfer

    def create_objects!
      child_tube = api.tube_from_tube_creation.create!(
        parent: labware.uuid,
        child_purpose: purpose_uuid,
        user: user_uuid
      ).child

      @tube_transfer = api.transfer_template.find(
        Settings.transfer_templates['Transfer between specific tubes']
      ).create!(
        user: user_uuid,
        source: labware.uuid,
        destination: child_tube.uuid
      )
      true
    rescue => e
      false
    end

    # We pretend that we've added a new blank tube when we're actually
    # transfering to the tube on the original LibraryRequest
    def child
      tube_transfer.try(:destination) || :contents_not_transfered
    end
  end
end
