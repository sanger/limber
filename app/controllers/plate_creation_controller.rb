#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class PlateCreationController < CreationController
  self.creation_message = 'New empty plate added to system.'

  def form_lookup(form_attributes = params)
    Settings.purposes[form_attributes[:purpose_uuid]][:form_class].constantize
  end

  def redirection_path(form)
    limber_plate_path(form.child.uuid)
  end
end
