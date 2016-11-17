# frozen_string_literal: true

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
