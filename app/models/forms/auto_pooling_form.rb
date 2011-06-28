module Forms
  class AutoPoolingForm < CreationForm
    write_inheritable_attribute :page, 'auto_pooling'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :transfer_template_uuid]

    def transfer_template_uuids
      [
        [ 'Pool wells based on submission', Settings.transfer_templates['Pool wells based on submission'] ]
      ]
    end

    def create_objects!
      create_plate!(transfer_template_uuid)
    end
    private :create_objects!
  end
end
