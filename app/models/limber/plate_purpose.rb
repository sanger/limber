#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class Limber::PlatePurpose < Sequencescape::PlatePurpose

  def is_qc?
    Settings.qc_purposes.include?(name)
  end

  def not_qc?
    !is_qc?
  end

  def asset_type
    Settings.purposes[uuid].asset_type
  end
end
