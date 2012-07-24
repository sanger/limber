module Forms
  module Form
    module CustomPage
      # We need to do something special at this point in order to create the plate.
      def render(controller)
        controller.render(self.page)
      end
    end

    module NoCustomPage
      # By default forms need no special processing to they actually do the creation and then
      # redirect.  If you have a special form to display include Forms::Form::CustomPage
      def render(controller)
        raise StandardError, "Not saving #{self.class} form...." unless save!
        controller.redirect_to_form_destination(self)
      end
    end

    def self.included(base)
      base.class_eval do
        extend ActiveModel::Naming
        include ActiveModel::Conversion
        include ActiveModel::Validations
        include NoCustomPage

        class_inheritable_reader :page
        write_inheritable_attribute :page, 'new'

        class_inheritable_reader :aliquot_partial
        write_inheritable_attribute :aliquot_partial, 'lab_ware/aliquot'

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
    include PlateWalking

    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :user_uuid]

    class_inheritable_reader :default_transfer_template_uuid
    write_inheritable_attribute :default_transfer_template_uuid, Settings.transfer_templates['Transfer columns 1-12']

    attr_reader :plate_creation

    def plate_to_walk
      self.parent
    end

    validates_presence_of attributes

    def child
      plate_creation.try(:child) || :child_not_created
    end

    def child_purpose
      @child_purpose ||= api.plate_purpose.find(plate_purpose_uuid)
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end
    alias_method(:plate, :parent)

    def save!
      raise StandardError, 'Invalid data' unless valid?

      create_objects!
    end

    def create_plate!(selected_transfer_template_uuid = default_transfer_template_uuid, &block)
      @plate_creation = api.plate_creation.create!(
        :parent              => parent_uuid,
        :child_purpose => plate_purpose_uuid,
        :user                => user_uuid
      )

      api.transfer_template.find(selected_transfer_template_uuid).create!(
        :source      => parent_uuid,
        :destination => @plate_creation.child.uuid,
        :user        => user_uuid
      )

      yield(@plate_creation.child) if block_given?
      true
    end
    private :create_plate!

    alias_method(:create_objects!, :create_plate!)
  end
end
