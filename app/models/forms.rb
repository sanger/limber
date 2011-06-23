module Forms

  TRANSFERS = {
    "Transfer columns 1-1"                             => "00ab41b2-9b2e-11e0-9da5-005056a80079",
    "Transfer columns 1-2"                             => "00affe78-9b2e-11e0-9da5-005056a80079",
    "Transfer columns 1-3"                             => "00b252f4-9b2e-11e0-9da5-005056a80079",
    "Transfer columns 1-4"                             => "00b5e45a-9b2e-11e0-9da5-005056a80079",
    "Transfer columns 1-6"                             => "00c243e4-9b2e-11e0-9da5-005056a80079",
    "Transfer columns 1-12"                            => "00e6d4de-9b2e-11e0-9da5-005056a80079",
    "Pool wells based on submission"                   => "00e80976-9b2e-11e0-9da5-005056a80079",
    "Transfer wells to MX library tubes by submission" => "00e95920-9b2e-11e0-9da5-005056a80079"
  }
  

 
 class CreationForm
    extend ActiveModel::Naming
    include ActiveModel::Validations

    def persisted?
      false
    end

    PAGE       = 'new'
    ATTRIBUTES = [:api, :plate_purpose_uuid, :parent_uuid]

    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

    def page
      self.class.const_get(:PAGE)
    end

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end
    end

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

    def save
      return false unless valid?

      create_objects!
    end

    def default_transfer_template_uuid
      TRANSFERS['Transfer columns 1-12']
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

  def self.lookup_form(uuid)
    FormLookUp.lookup(uuid)
  end

end
