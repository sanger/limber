# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2012 Genome Research Ltd.
module Limber::TagLayoutTemplate::InRows
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      ('A'..'H').map do |row|
        (1..12).map do |column|
          well_location_pool_pair.call(row, column)
        end
      end
    end
  end
end
