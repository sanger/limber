#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module Presenters
  class FullFailablePresenter < FailablePresenter

    include Presenters::ExtendedCsv

  end
end
