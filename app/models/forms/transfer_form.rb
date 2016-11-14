# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
module Forms
  class TransferForm < CreationForm
    include Forms::Form::CustomPage

    self.page = 'robot'
    self.attributes = [:api, :user_uuid, :purpose_uuid, :parent_uuid, :transfer_template_uuid]

    validates presence: attributes

    def transfer_template_uuids
      Settings.transfer_templates.select { |name, _| name =~ /columns \d+-\d+/ }.to_a.reverse
    end

    def create_objects!
      create_plate!(transfer_template_uuid)
    end
    private :create_objects!
  end
end
