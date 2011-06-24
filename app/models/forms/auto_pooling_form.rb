module Forms
  class AutoPoolingForm < CreationForm
    write_inheritable_attribute :page, 'robot'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :transfer_template_uuid]
    

    def transfer_template_uuids
      # TODO this should do a look up on the pooling by submission uuid
      # locally and the a direct find
      @transfer_template_uuids ||= api.transfer_template.all.select { |transfer| transfer.name.match(/Pool/) }
    end

    def create_objects!
      create_plate!(transfer_template_uuid)
    end
    private :create_objects!
  end
end
