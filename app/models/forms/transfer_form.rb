module Forms
  class TransferForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'robot'
    write_inheritable_attribute :attributes, [:api, :user_uuid, :purpose_uuid, :parent_uuid, :transfer_template_uuid]

    validates_presence_of *self.attributes

    def transfer_template_uuids
      Settings.transfer_templates.select { |name, _| name =~ /columns \d+-\d+/ }.to_a.reverse
    end

    def create_objects!
      create_plate!(transfer_template_uuid)
    end
    private :create_objects!
  end
end
