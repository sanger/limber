module Forms
  class CustomPoolingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'custom_pooling'
    write_inheritable_attribute :aliquot_partial, "custom_pooled_aliquot"

    write_inheritable_attribute :default_transfer_template_uuid, 
      Settings.transfer_templates['Pool wells based on submission']

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

    def transfer_preview
      @transfer_preview ||= TransferHelper.new( 
        api.transfer_template.find(
          self.default_transfer_template_uuid
        ).preview!(
          :source      => parent_uuid, 
          :destination => parent_uuid
        ).transfers
      )
    end

    def transfers
      transfer_preview
    end

    def walk_source
      # Populate this based on the pooling preview...
      PlateWalking::Walker.new(parent.wells)
    end
    
    def walk_destination
      # Populate this based on the pooling preview...
      # PlateWalking::Walker.new(destination_plate.wells)
    end


    def create_plate!
      # TODO cary out the transfer...
    end
  end
end
