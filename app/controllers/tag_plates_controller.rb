#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class TagPlatesController < ApplicationController

  def show
    qcable = Presenters::QcablePresenter.new(api.qcable.find(params[:id]))
    respond_to do |format|
      format.json { render :json => {'qcable'=>qcable } }
    end
  end

end
