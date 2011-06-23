module Forms
  class TransferForm < CreationForm
    write_inheritable_attribute :page, 'robot'
    ATTRIBUTES = [:api, :plate_purpose_uuid, :parent_uuid, :transfer_template_uuid]

    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    validates_presence_of *ATTRIBUTES
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
