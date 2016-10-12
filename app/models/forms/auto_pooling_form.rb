#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
module Forms
  class AutoPoolingForm < CreationForm
    include Forms::Form::NoCustomPage

    self.page =  'auto_pooling'
    self.attributes =  [:api, :user_uuid, :purpose_uuid, :parent_uuid, :transfer_template_uuid]
    self.default_transfer_template_uuid =  Settings.transfer_templates['Pool wells based on submission']


    def save!
      raise StandardError, 'Invalid data; ' + self.errors.full_messages.join('; ') unless valid?
      create_objects! do |plate|
        api.transfer_template.find(Settings.transfer_templates["Transfer wells to MX library tubes by submission"]).create!(
          :source => plate.uuid,
          :user   => user_uuid
        )
      end
    end
  end
end
