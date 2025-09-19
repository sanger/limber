# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesFromWholeTubes do
  include FeatureHelpers

  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from tubes'

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }

  let(:parents) { create_list :v2_tube, 2 }
  let(:parent_uuid) { parents.first.uuid }

  let(:barcodes) { parents.map { |parent| parent.barcode.to_s } }

  let(:child_tube) { create(:v2_tube) }

  describe '#new' do
    it_behaves_like 'it has a custom page', 'pooled_tubes_from_whole_tubes'

    let(:form_attributes) { { purpose_uuid:, parent_uuid: } }
  end

  describe '#save!' do
    let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid:, barcodes: } }

    let(:transfer_requests_attributes) do
      parents.map { |parent| { source_asset: parent.uuid, target_asset: child_tube.uuid } }
    end

    let(:tube_from_tubes_attributes) do
      [{ child_purpose_uuid: purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid }]
    end

    before do
      allow(Sequencescape::Api::V2::Tube).to receive(:find_all).with({ barcode: barcodes }, includes: []).and_return(
        parents
      )
    end

    context 'with compatible tubes' do
      it 'pools from all the tubes' do
        expect_transfer_request_collection_creation
        expect_tube_from_tube_creation

        expect(subject.save!).to be_truthy
      end
    end
  end
end
