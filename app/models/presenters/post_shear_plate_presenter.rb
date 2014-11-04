module Presenters
  class PostShearPlatePresenter < StandardPresenter

    write_inheritable_attribute :robot_controlled_states, {
      :pending => 'shear-post-shear'
    }

        # Returns the child plate purposes that can be created in the qc_complete state.
    def default_child_purpose
      labware.plate_purpose.children.detect do |purpose|
        not_qc?(purpose) && suitable_child?(purpose)
      end
    end

    def not_qc?(purpose)
      !Settings.qc_purposes.include?(purpose.name)
    end
    private :not_qc?

    def suitable_child?(purpose)
      Settings.purposes[labware.plate_purpose.uuid].locations_children.nil? ||
      Settings.purposes[labware.plate_purpose.uuid].locations_children[location] == purpose.name
    end
    private :suitable_child?

  end
end
