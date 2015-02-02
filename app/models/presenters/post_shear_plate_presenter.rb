module Presenters
  class PostShearPlatePresenter < StandardPresenter

    # Returns the child plate purposes that can be created in the qc_complete state.
    def default_child_purpose
      labware.plate_purpose.children.detect do |purpose|
        purpose.not_qc? && suitable_child?(purpose)
      end
    end

    def valid_purposes
      yield default_child_purpose
    end

    def suitable_child?(purpose)
      Settings.purposes[labware.plate_purpose.uuid].locations_children.nil? ||
      Settings.purposes[labware.plate_purpose.uuid].locations_children[location] == purpose.name
    end
    private :suitable_child?

  end
end
