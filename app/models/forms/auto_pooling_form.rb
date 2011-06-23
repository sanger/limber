module Forms
  class AutoPoolingForm < CreationForm
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
