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
    poly_metadatum =
      create(
        :poly_metadatum,
        key: scrna_config[:number_of_cells_per_chip_well_key],
        value: '30000'
      )
    create(
      :v2_well_with_transfer_requests_and_polymetadata,
      location: 'A1',
      transfer_requests_as_target: transfers_to_a1,
      plate_barcode: 'DN3U',
      poly_metadata: [poly_metadatum]
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
    poly_metadatum =
      create(
        :poly_metadatum,
        key: scrna_config[:number_of_cells_per_chip_well_key],
        value: '30000'
      )
    create(
      :v2_well_with_transfer_requests_and_polymetadata,
      location: 'B1',
      transfer_requests_as_target: transfers_to_b1,
      plate_barcode: 'DN3U',
      poly_metadata: [poly_metadatum]
    )
  end

  let(:all_dest_wells) { [dest_well_a1, dest_well_b1] }

  let(:labware) { create :v2_plate, wells: all_dest_wells, barcode_number: 3 }

  # Studies to assign to aliquots

  # empty poly_metadata
  let(:study_to_a1) do
    create(:study_with_poly_metadata, name: 'First Study', poly_metadata: [])
  end
  # empty poly_metadata
  let(:study_to_b1) do
    create(:study_with_poly_metadata, name: 'Second Study', poly_metadata: [])
  end

  # Constants from config/initializers/scrna_config.rb
  let(:scrna_config) { Rails.application.config.scrna_config }

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

  context 'when displaying the pooling info' do
    context 'when all wells have the same number of aliquots' do
      it 'returns the correct count' do
        wells = [dest_well_a1, dest_well_b1]
        expect(subject.num_samples_per_pool(wells)).to eq '1'
      end
    end

    context 'when wells have different numbers of aliquots' do
      it 'returns a comma-separated list' do
        allow(dest_well_a1).to receive(:aliquots).and_return([double, double])
        allow(dest_well_b1).to receive(:aliquots).and_return([double, double, double])
        wells = [dest_well_a1, dest_well_b1]
        expect(subject.num_samples_per_pool(wells)).to eq '2, 3'
      end
    end

    it 'returns a comma-separated list of well positions' do
      wells = [source_well_a1, source_well_b1, source_well_c1]
      expect(subject.get_source_wells(wells)).to eq 'A1, B1, D1'
    end

    it 'returns "Unknown" for wells without a position name' do
      allow(source_well_a1).to receive(:position).and_return({})
      wells = [source_well_a1]
      expect(subject.get_source_wells(wells)).to eq 'Unknown'
    end

    it 'returns a delimited string for the cell count value' do
      expect(subject.cells_per_chip_well(dest_well_a1)).to eq '30,000'
    end

    it 'returns nil if no matching poly_metadata is found' do
      allow(dest_well_a1).to receive(:poly_metadata).and_return([])
      expect(subject.cells_per_chip_well(dest_well_a1)).to be_nil
    end

    it 'returns the correct study and project groups from wells' do
      expected_groups = [['Well Study / Well Project', [dest_well_a1, dest_well_b1]]]
      expect(subject.study_project_groups_from_wells).to eq expected_groups
    end

    it 'returns true for show_scrna_pooling?' do
      expect(subject.show_scrna_pooling?).to be true
    end
  end
end
