#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
module Forms
  class AutoPoolingForm < CreationForm
    include Forms::Form::NoCustomPage

    write_inheritable_attribute :page, 'auto_pooling'
    write_inheritable_attribute :attributes, [:api, :user_uuid, :purpose_uuid, :parent_uuid, :transfer_template_uuid]
    write_inheritable_attribute :default_transfer_template_uuid, Settings.transfer_templates['Pool wells based on submission']
  end
end
