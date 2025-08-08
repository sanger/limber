# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Presenters::DonorPoolingPlatePresenter do
  # First set of source wells

  subject { described_class.new(labware:) }

  let(:source_well_a1) { create(:v2_well, location: 'A1') }
  let(:source_well_b1) { create(:v2_well, location: 'B1') }
  let(:source_well_c1) { create(:v2_well, location: 'D1') }
  let(:source_well_d1) { create(:v2_well, location: 'C1') }

  # target_asset is nil because it causes cycles and not used in this test
  let(:transfer_request_a1) { create(:v2_transfer_request, source_asset: source_well_a1, target_asset: nil) }
  let(:transfer_request_b1) { create(:v2_transfer_request, source_asset: source_well_b1, target_asset: nil) }
  let(:transfer_request_c1) { create(:v2_transfer_request, source_asset: source_well_c1, target_asset: nil) }
  let(:transfer_request_d1) { create(:v2_transfer_request, source_asset: source_well_d1, target_asset: nil) }

  # First destination well

  let(:source_wells_to_a1) { [source_well_a1, source_well_b1, source_well_c1, source_well_d1] }
  let(:transfers_to_a1) { [transfer_request_a1, transfer_request_b1, transfer_request_c1, transfer_request_d1] }

  let(:dest_well_a1) do
    create(
      :v2_well_with_transfer_requests,
      location: 'A1',
      transfer_requests_as_target: transfers_to_a1,
      plate_barcode: 'DN3U'
    )
  end

  # Letters continued from above to make it easier to follow

  # Second set of source wells

  let(:source_well_e1) { create(:v2_well, location: 'E1') }
  let(:source_well_f1) { create(:v2_well, location: 'F1') }
  let(:source_well_g1) { create(:v2_well, location: 'G1') }
  let(:source_well_h1) { create(:v2_well, location: 'H1') }

  # target_asset is nil because it causes cycles and not used in this test
  let(:transfer_request_e1) { create(:v2_transfer_request, source_asset: source_well_e1, target_asset: nil) }
  let(:transfer_request_f1) { create(:v2_transfer_request, source_asset: source_well_f1, target_asset: nil) }
  let(:transfer_request_g1) { create(:v2_transfer_request, source_asset: source_well_g1, target_asset: nil) }
  let(:transfer_request_h1) { create(:v2_transfer_request, source_asset: source_well_h1, target_asset: nil) }

  # Second destination well

  let(:source_wells_to_b1) { [source_well_e1, source_well_f1, source_well_g1, source_well_h1] }
  let(:transfers_to_b1) { [transfer_request_e1, transfer_request_f1, transfer_request_g1, transfer_request_h1] }

  let(:dest_well_b1) do
    create(
      :v2_well_with_transfer_requests,
      location: 'B1',
      transfer_requests_as_target: transfers_to_b1,
      plate_barcode: 'DN3U'
    )
  end

  let(:all_dest_wells) { [dest_well_a1, dest_well_b1] }

  let(:labware) { create :v2_plate, wells: all_dest_wells, barcode_number: 3 }

  # Studies to assign to aliquots

  let(:study_to_a1) { create(:study_with_poly_metadata, name: 'First Study', poly_metadata: []) } # empty poly_metadata
  let(:study_to_b1) { create(:study_with_poly_metadata, name: 'Second Study', poly_metadata: []) } # empty poly_metadata

  before do
    Settings.purposes = { labware.purpose.uuid => { presenter_class: {} } }
    source_wells_to_a1.each { |well| allow(well.aliquots.first).to receive(:study).and_return(study_to_a1) }
    source_wells_to_b1.each { |well| allow(well.aliquots.first).to receive(:study).and_return(study_to_b1) }
  end

  context 'when the labware not in pending state' do
    before { allow(labware).to receive(:state).and_return('passed') }

    it 'does not warn the user about any study' do
      expect(subject).to be_valid # There are no warnings.
    end
  end
end
