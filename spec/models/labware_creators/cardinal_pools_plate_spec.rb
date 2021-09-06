# frozen_string_literal: true

require 'spec_helper'
# require 'labware_creators/base'
# require_relative '../../support/shared_tagging_examples'
# require_relative 'shared_examples'

# Presents the user with a form allowing them to scan in up to four plates
# which will then be pooled together according to pre-capture pools
RSpec.describe LabwareCreators::CardinalPoolsPlate, cardinal: true do
  # it_behaves_like 'it only allows creation from tagged plates'

  has_a_working_api
  
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:parent_uuid)        { 'example-plate-uuid' }
  let(:user_uuid)          { 'user-uuid' }

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid: parent_uuid,
      user_uuid: user_uuid
    }
  end

  subject do
    LabwareCreators::CardinalPoolsPlate.new(api, form_attributes)
  end

  context 'on new' do
    it 'can be initialised' do
      expect(subject).to be_a LabwareCreators::CardinalPoolsPlate
    end

    
    it 'has the config loaded' do
      expect(subject.class.pooling_config).to eq({ test: "hi" })
    end

    # context 'when wells are missing a concentration value' do
    #   let(:well_e1) do
    #     create(:v2_well,
    #            position: { 'name' => 'E1' },
    #            qc_results: [])
    #   end

    #   let(:parent_plate) do
    #     create :v2_plate,
    #            uuid: parent_uuid,
    #            barcode_number: '2',
    #            size: plate_size,
    #            wells: [well_a1, well_b1, well_c1, well_d1, well_e1],
    #            outer_requests: requests
    #   end

    #   it 'fails validation' do
    #     expect(subject).to_not be_valid
    #   end
    # end
  end

  # context 'on create' do
  #   context '#save!' do
  #     it 'creates a plate!' do
  #       subject.save!
  #     end
  #   end
  # end
end