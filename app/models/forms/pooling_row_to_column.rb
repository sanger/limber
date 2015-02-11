#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
module Forms
  class PoolingRowToColumn < CreationForm
    include Forms::Form::NoCustomPage

    write_inheritable_attribute :default_transfer_template_uuid, Settings.transfer_templates['Pooling rows to first column']
  end
end
