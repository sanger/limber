#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.
module Presenters
  class PostShearPlatePresenter < StandardPresenter

    # Returns the child plate purposes that can be created in the qc_complete state.
    def default_child_purpose
      labware.plate_purpose.children.detect do |purpose|
        purpose.not_qc? && suitable_child?(purpose)
      end
    end

    def valid_purposes
      yield default_child_purpose unless default_child_purpose.nil?
      nil
    end

    def suitable_child?(purpose)
      Settings.purposes.default_child.nil? ||
      Settings.purposes.default_child == purpose.name
    end
    private :suitable_child?

  end
end
