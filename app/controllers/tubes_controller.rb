#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
class TubesController < LabwareController
  write_inheritable_attribute :creation_message, 'The tubes have been created'

  def locate_labware_identified_by(id)
    api.multiplexed_library_tube.find(params[:id])
  end

  def presenter_for(labware)
    Presenters::TubePresenter.lookup_for(labware).new(
      :api     => api,
      :labware => labware
    )
  end

end
