# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
module SearchHelper
  def search_status(search_results)
    if search_results.present?
      'Search Results'
    else
      'No plates found.'
    end
  end
end
