# frozen_string_literal: true

# Handles the generation of two 96-well child plates from up to four 96-well source plates.
# In the client, the user will be able to scan 1-4 96-wells plate barcodes to
# create a pair of 96-well plates.
# Transfers are the first 3 columns from each of the four sources, into sets of 3 columns
# on the destination (source 1 to columns 1-3, source 2 to columns 4-6, source 3 to columns 7-9,
# and source 4 to columns 10-12).
#
# Eg.
#
# Plate 1        Plate 2         Dest. Plate
# +--+--+--~     +--+--+--~      +----+----+----+----+----+----~
# |A1|A2|A3      |A1|A2|A3       |P1A1|P1A2|P1A3|P2A1|P2A2|P2A3
# +--+--+--~     +--+--+--~      +----+----+----+----+----+----~
# |B1|B2|B3      |B1|B2|B3       |P1B1|P1B2|P1B3|P2B1|P2B2|P2B3
# +--+--+--~  +  +--+--+--~  =>  +----+----+----+----+----+----~
# |C1|C2|C3      |C1|C2|C3       |P1C1|P1C2|P1C3|P2C1|P2C2|P2C3
# +--+--+--~     +--+--+--~      +----+----+----+----+----+----~
# |D1|D2|D3      |D1|D2|D3       |P1D1|P1D2|P1D3|P2D1|P2D2|P2D3
#
# The user must specify a volume value which will be recorded on each
# transfer request. The transfer creator logic 'with-volume' is implemented
# client side.

module LabwareCreators
    class MultiStampLibrarySplitter < MultiStamp # rubocop:todo Style/Documentation
      class_attribute :max_wells_count
      
      self.page = 'multi_stamp_library_splitter'

      self.transfers_layout = 'sequentialLibrarySplit'
      self.transfers_creator = 'with-volume'
      self.attributes += [
        {
          transfers: [
            [:source_plate, :source_asset, :outer_request, :pool_index, { new_target: :location }, :volume]
          ]
        }
      ]
      self.target_rows = 8
      self.target_columns = 12
      self.source_plates = 4
      self.max_wells_count = 24

      #
      # We've created multiple plates, so we redirect to the parent.
      #
      # @return [Sequencescape::Api::V2::Plate] The parent plate
      def redirection_target
        parent
      end

      def anchor
        'children_tab'
      end
  
      private

      def create_labware!
        children_purposes_uuids.each do |purpose_uuid|
          _create_labware_with_purpose!(purpose_uuid)
        end
      end

      def children_purposes_uuids
        purpose_config.fetch(:creator_class, {}).fetch(:args, {}).fetch(:children_purposes, []).map do |name|
          all_purposes_uuids_by_name[name]
        end
      end

      def all_purposes_uuids_by_name
        Settings.purposes.map{|uuid, obj| { "#{obj[:name]}" => uuid}}.reduce{|m,v| m.merge(v)}
      end

      def _create_labware_with_purpose!(purpose_uuid)
        plate_creation = api.pooled_plate_creation.create!(
          parents: parent_uuids,
          child_purpose: purpose_uuid,
          user: user_uuid
        )
  
        @child = plate_creation.child

        transfer_material_from_parent!(@child)
  
        yield(@child) if block_given?
        true
      end

      def transfer_material_from_parent!(child_plate)
        api.transfer_request_collection.create!(
          user: user_uuid,
          transfer_requests: transfer_request_attributes(child_plate)
        )
      end
  
      def transfer_request_attributes(child_plate)
        transfers.map do |transfer|
          request_hash(transfer, child_plate)
        end
      end  

      def outer_request_for_library_type(well_uuid, library_type)
        parent_plates.each do |plate|
          well = plate.wells.select{|w| w.uuid == well_uuid }.first
          if well
            found = well.requests_as_source.select{|r| r.library_type == library_type }
            return found.first if found
          end
        end
      end
  
      def request_hash(transfer, child_plate)
        transfer.merge({
          'target_asset' => child_plate.wells.detect do |child_well|
            child_well.location == transfer.dig(:new_target, :location)
          end&.uuid,
          'outer_request' => outer_request_for_library_type(transfer[:source_asset], library_type_for_plate(child_plate)).uuid
        })
      end
  
      def library_type_for_plate(plate)
        @_memo ||= {}
        @_memo[plate.purpose.name] ||= purpose_for_name(plate.purpose.name).dig(:transfer_library_type)
      end

      def purpose_for_name(name)
        Settings.purposes.each do |uuid,obj|
          return obj if obj[:name] == name
        end
      end

      def parent_plates
        @parent_plates ||= Sequencescape::Api::V2::Plate.find_all({ 
          uuid: parent_uuids 
          }, includes: 'purpose,parents,wells.aliquots.request,wells.requests_as_source')
      end

    end
  end
  