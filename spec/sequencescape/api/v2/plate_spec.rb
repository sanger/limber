# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Plate do
  subject(:plate) { create :v2_plate, barcode_number: 12_345 }

  it { is_expected.to be_plate }
  it { is_expected.to_not be_tube }

  describe '#human_barcode' do
    it 'returns the human readable barcode' do
      expect(plate.human_barcode).to eq('DN12345U')
    end
  end

  describe '#labware_barcode' do
    it 'returns a LabwareBarcode' do
      expect(plate.labware_barcode).to be_a LabwareBarcode
    end
    it 'has the correct values' do
      expect(plate.labware_barcode.human).to eq('DN12345U')
      expect(plate.labware_barcode.machine).to eq('1220012345855')
      # TODO: Remove this functionality
      expect(plate.labware_barcode.number).to eq('12345')
      expect(plate.labware_barcode.prefix).to eq('DN')
    end
  end

  describe '::find_by' do
    let(:plate) { create(:v2_plate) }
    before do
      # Consider actually mocking at the request level
      stub_api_v2(
        'Plate',
        includes: [
          :purpose,
          { wells: [
            :downstream_assets,
            {
              requests_as_source: %w[request_type primer_panel pre_capture_pool],
              aliquots: ['sample', { request: %w[request_type primer_panel pre_capture_pool] }]
            }
          ] }
        ],
        where: { uuid: plate.uuid },
        first: plate
      )
    end
    it 'finds a plate' do
      expect(Sequencescape::Api::V2::Plate.find_by(uuid: plate.uuid)).to be_a Sequencescape::Api::V2::Plate
    end
  end
end
