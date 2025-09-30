# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Parent in a plate
# Creates new tubes of the child purpose
# Each well on the plate gets transferred into a tube
# transfer targets are determined by pool
RSpec.describe LabwareCreators::PooledTubesFromWholePlates, with: :uploader do
  include FeatureHelpers

  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from tagged plates'

  it 'has page' do
    expect(described_class.page).to eq 'pooled_tubes_from_whole_plates'
  end

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:parent2_uuid) { SecureRandom.uuid }
  let(:parent3_uuid) { SecureRandom.uuid }
  let(:parent4_uuid) { SecureRandom.uuid }

  let(:parent) { create :plate, uuid: parent_uuid, barcode_number: 1 }
  let(:parent2) { create :plate, uuid: parent2_uuid, barcode_number: 2 }
  let(:parent3) { create :plate, uuid: parent3_uuid, barcode_number: 3 }
  let(:parent4) { create :plate, uuid: parent4_uuid, barcode_number: 4 }

  let(:barcodes) do
    [
      SBCF::SangerBarcode.new(prefix: 'DN', number: 1).human_barcode,
      SBCF::SangerBarcode.new(prefix: 'DN', number: 2).human_barcode,
      SBCF::SangerBarcode.new(prefix: 'DN', number: 3).human_barcode,
      SBCF::SangerBarcode.new(prefix: 'DN', number: 4).human_barcode
    ]
  end

  describe '#new' do
    it_behaves_like 'it has a custom page', 'pooled_tubes_from_whole_plates'

    let(:form_attributes) { { purpose_uuid:, parent_uuid: } }
  end

  describe '#save!' do
    let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid:, barcodes: } }

    let(:child_tube) { create :tube }
    let(:specific_tubes_attributes) do
      [{ uuid: purpose_uuid, parent_uuids: [parent_uuid], child_tubes: [child_tube], tube_attributes: [{}] }]
    end

    let(:transfers_attributes) do
      [parent_uuid, parent2_uuid, parent3_uuid, parent4_uuid].map do |source_uuid|
        {
          arguments: {
            user_uuid: user_uuid,
            source_uuid: source_uuid,
            destination_uuid: child_tube.uuid,
            transfer_template_uuid: 'whole-plate-to-tube'
          }
        }
      end
    end

    before { stub_asset_search(barcodes, [parent, parent2, parent3, parent4]) }

    context 'with compatible plates' do
      it 'pools from all the plates' do
        expect_specific_tube_creation
        expect_transfer_creation

        expect(subject.save!).to be_truthy
      end
    end
  end
end
