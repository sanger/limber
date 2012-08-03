module Forms
  class CustomPoolingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'custom_pooling'
    write_inheritable_attribute :aliquot_partial, "custom_pooled_aliquot"

    write_inheritable_attribute :default_transfer_template_uuid,
      Settings.transfer_templates['Pool wells based on submission']

    write_inheritable_attribute :attributes, [:api, :purpose_uuid, :parent_uuid, :user_uuid, :transfers]

    class TransferHelper
      def initialize(transfers)
        @transfers = transfers
      end


      def method_missing(name, *args, &block)
        return @transfers[name.to_s] if name.to_s =~ /^[A-H]\d+$/

        @transfers.send(name, *args, &block)
      end

      def respond_to?(name, include_private = false)
        (name.to_s =~ /^[A-H]\d+$/) or @transfers.respond_to?(name, include_private)
      end
    end

    class Well
      attr_reader :location, :aliquots

      def initialize(location)
        @location = location
        @aliquots = [:AN_ALIQUOT]
      end
    end

    def pools_by_well
      @pools_by_well ||= Hash[plate.wells.map { |well| [well.location, well.pool_id] }]
    end

    def pool(location)
      pools_by_well[location]
    end

    def transfer_preview
      @transfer_preview ||= TransferHelper.new(
        api.transfer_template.find(
          self.default_transfer_template_uuid
        ).preview!(
          :source      => parent_uuid,
          :destination => parent_uuid,
          :user        => user_uuid
        ).transfers
      )
    end

    def transfers
      @transfers || transfer_preview
    end

    def source_wells_by_row
      PlateWalking::Walker.new(plate, plate.wells)
    end

    def wells_by_row
      rows = Hash[('A'..'H').map { |row| [ row, [] ] }]

      transfers.values.uniq.map do |location|
        [PlateWalking::Walker::Location.new(location), CustomPoolingForm::Well.new(location)]
      end.group_by do |location, _|
        location.row
      end.map do |row, location_and_well_pairs|
        rows[row] = location_and_well_pairs.sort { |(a,_),(b,_)| a.column <=> b.column }.map(&:last)
      end

      rows
    end


    def create_objects!(selected_transfer_template_uuid = default_transfer_template_uuid, &block)
      @plate_creation = api.plate_creation.create!(
        :parent        => parent_uuid,
        :child_purpose => purpose_uuid,
        :user          => user_uuid
      )


      api.transfer_template.find(Settings.transfer_templates['Custom pooling']).create!(
        :source      => parent_uuid,
        :destination => @plate_creation.child.uuid,
        :user        => user_uuid,
        :transfers   => transfers
      )

      yield(@plate_creation.child) if block_given?
      true
    end
    private :create_objects!
  end
end

