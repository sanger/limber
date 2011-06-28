module Forms
  module Form
    def self.included(base)
      base.class_eval do
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        include ActiveModel::Validations

        class_inheritable_reader :page
        write_inheritable_attribute :page, 'new'

        class_inheritable_reader :attributes
      end
    end

    def initialize(attributes = {})
      self.attributes.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

    def method_missing(name, *args, &block)
      name_without_assignment = name.to_s.sub(/=$/, '').to_sym
      return super unless attributes.include?(name_without_assignment)

      instance_variable_name = :"@#{name_without_assignment}"
      return instance_variable_get(instance_variable_name) if name_without_assignment == name.to_sym
      instance_variable_set(instance_variable_name, args.first)
    end
    protected :method_missing

    def persisted?
      false
    end
  end

  class CreationForm
    include Form

    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid]

    attr_reader :plate_creation

    # validates_presence_of *ATTRIBUTES

    def child
      plate_creation.try(:child) || :child_not_created
    end

    def child_plate_purpose
      @child_plate_purpose ||= api.plate_purpose.find(plate_purpose_uuid)
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end
    alias_method(:plate, :parent)

    def save
      return false unless valid?

      create_objects!
    end

    def default_transfer_template_uuid
      Settings.transfer_templates['Transfer columns 1-12']
    end
    private :default_transfer_template_uuid

    def create_plate!(transfer_template_uuid = default_transfer_template_uuid, &block)
      @plate_creation = api.plate_creation.create!(
        :parent              => parent_uuid,
        :child_plate_purpose => plate_purpose_uuid
        # :user_uuid           => user_uuid
      )

      api.transfer_template.find(transfer_template_uuid).create!(
        :source      => parent_uuid,
        :destination => @plate_creation.child.uuid
        # :user => :user_id
      )

      yield(@plate_creation.child) if block_given?
      true
    rescue => e
      false
    end
    private :create_plate!

    alias_method(:create_objects!, :create_plate!)
  end
end
