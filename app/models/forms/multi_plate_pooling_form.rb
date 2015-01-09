module Forms
  class MultiPlatePoolingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'multi_plate_pooling'
    write_inheritable_attribute :aliquot_partial, "custom_pooled_aliquot"

    write_inheritable_attribute :default_transfer_template_uuid,
      Settings.transfer_templates['Pool wells based on submission']

    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :user_uuid, :transfers, :plates]

    write_inheritable_attribute :tab_views, {
      'add-plates' => [
        'add-plates-instructions-block','add-plates-block'
      ],

      # 'edit-pool' => [
      #   'edit-pool-instruction-block', 'input-plate-block',
      #               'edit-pool-block', 'output-plate-block'
      # ],

      'pooling-summary' => [
        'pooling-summary-block', 'input-plate-block',
           'create-plate-block', 'output-plate-block'
      ]
    }


    def create_objects!(selected_transfer_template_uuid = default_transfer_template_uuid, &block)

      @plate_creation = api.pooled_plate_creation.create!(
        :parents       => transfers.keys,
        :child_purpose => plate_purpose_uuid,
        :user          => user_uuid
      )

      api.bulk_transfer.create!(
        :source      => parent_uuid,
        :user        => user_uuid,
        :well_transfers   => well_transfers
      )

      yield(@plate_creation.child) if block_given?
      true
    end
    private :create_objects!

    def well_transfers
      transfers = []
      each_well do |source_uuid,source_well,destination_uuid,destination_well|
        transfers << {
          "source_uuid" => source_uuid,
          "source_location" => source_well,
          "destination_uuid" => destination_uuid,
          "destination_location" => destination_well
        }
      end
      transfers
    end
    private :well_transfers

    def each_well
      transfers.each do |source_uuid, transfers|
        transfers.each do |source_well, destination_well|
          yield(source_uuid,source_well,@plate_creation.child.uuid,destination_well)
        end
      end
    end
    private :each_well

  end
end

