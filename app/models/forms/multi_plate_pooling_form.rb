#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module Forms
  class MultiPlatePoolingForm < CreationForm
    include Forms::Form::CustomPage

    self.page =  'multi_plate_pooling'
    self.aliquot_partial =  "custom_pooled_aliquot"
    self.default_transfer_template_uuid = Settings.transfer_templates['Pool wells based on submission']
    self.attributes =  [:api, :purpose_uuid, :parent_uuid, :user_uuid, :transfers, :plates]

    def tab_views
      {
        'add-plates' => ['add-plates-instructions-block','add-plates-block'],
        'pooling-summary' => ['pooling-summary-block', 'input-plate-block',
             'create-plate-block', 'output-plate-block']
      }
    end

    def create_objects!(selected_transfer_template_uuid = default_transfer_template_uuid, &block)
      @plate_creation = api.pooled_plate_creation.create!(
        :parents       => transfers.keys,
        :child_purpose => purpose_uuid,
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

