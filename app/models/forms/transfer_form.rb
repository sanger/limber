module Forms
  class TransferForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'robot'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :transfer_template_uuid]

    validates_presence_of *self.attributes

    def transfer_template_uuids
      # This should be able to use the transfer-to-uuids list in Form.
      @transfer_template_uuids ||= (api.transfer_template.all.select { |template| template.name.match(/columns/) }.reverse)
    end

    def create_objects!
      create_plate!(transfer_template_uuid)
    end
    private :create_objects!
  end
end
