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
  

  class PlateForm
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations


    ATTRIBUTES = [:api, :plate, :state]

    attr_accessor *ATTRIBUTES

    def initialize(attributes = {})
      ATTRIBUTES.each do |attribute|
        send("#{attribute}=", attributes[attribute])
      end

      @state = @plate.state
    end

    def persisted?
      false
    end

    def save!
      api.state_change.create!(
        :target       => plate.uuid,
        :target_state => state
      )
    end
  end

  class CreationForm
    extend ActiveModel::Naming
    include ActiveModel::Validations

    def persisted?
      false
    end

    PARTIAL = 'new'

    ATTRIBUTES = [:api, :plate_purpose_uuid, :parent_uuid]

    attr_accessor *ATTRIBUTES
    attr_reader :plate_creation

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

  # FORM_UUIDS = {
    # "ba5b3efa-9809-11e0-9fe8-005056a80079" => CreationForm,       # "Stock Plate",
    # "20729912-95d6-11e0-821d-005056a80079" => CreationForm,       # WgsFragmentationPlate
    # "baa142ce-9809-11e0-9fe8-005056a80079" => CreationForm,       # "Pulldown PCR",
    # "baa2c4fa-9809-11e0-9fe8-005056a80079" => CreationForm,       # "Pulldown qPCR",
    # "20719198-95d6-11e0-821d-005056a80079" => CreationForm,       # "Pulldown stock plate",
    # "20729912-95d6-11e0-821d-005056a80079" => CreationForm,       # "WGS fragmentation plate",
    # "20740b58-95d6-11e0-821d-005056a80079" => CreationForm,       # "WGS fragment purification plate",
    # "207559a4-95d6-11e0-821d-005056a80079" => CreationForm,       # "WGS library preparation plate",
    # "2076b36c-95d6-11e0-821d-005056a80079" => WgsLibraryPlate,    # "WGS library plate",
    # "207800d2-95d6-11e0-821d-005056a80079" => WgsLibraryPcrPlate, # "WGS library PCR plate",
    # "20796e5e-95d6-11e0-821d-005056a80079" => CreationForm,       # "WGS amplified library plate",
    # "207ac150-95d6-11e0-821d-005056a80079" => CreationForm,       # "WGS pooled amplified library plate",
    # "207c0a2e-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC fragmentation plate",
    # "207d63d8-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC fragment purification plate",
    # "207ef5f4-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC library preparation plate",
    # "20980b70-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC library plate",
    # "2099624a-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC library PCR plate",
    # "209aa13c-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC amplified library plate",
    # "209bd6d8-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC hybridisation plate",
    # "209cffcc-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC captured library plate",
    # "209e2208-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC captured library PCR plate",
    # "209f41d8-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC amplified captured library plate",
    # "20a06a86-95d6-11e0-821d-005056a80079" => CreationForm,       # "SC pooled captured library plate",
    # "20a184f2-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC fragmentation plate",
    # "20a2a0f8-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC fragment purification plate",
    # "20a3ba42-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC library preparation plate",
    # "20a4d10c-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC library plate",
    # "20a5e9ac-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC library PCR plate",
    # "20a70418-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC amplified library plate",
    # "20a81c90-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC pooled amplified library plate",
    # "20a93166-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC hybridisation plate",
    # "20aa3fde-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC captured library plate",
    # "20ab8e66-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC captured library PCR plate",
    # "20acc6d2-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC amplified captured library plate",
    # "20c36a0e-95d6-11e0-821d-005056a80079" => CreationForm,       # "ISC pooled captured library plate",
    # "20c491ae-95d6-11e0-821d-005056a80079" => CreationForm        # "Pulldown QC plate"
  # }

  def self.lookup_form(uuid)
    FormLookUp.lookup(uuid)
  end
end
