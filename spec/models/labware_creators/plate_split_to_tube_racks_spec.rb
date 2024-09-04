# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PlateSplitToTubeRacks, with: :uploader do
  include FeatureHelpers

  has_a_working_api

  it_behaves_like 'it only allows creation from plates'

  subject { described_class.new(api, form_attributes) }

  it 'should have a custom page' do
    expect(described_class.page).to eq 'plate_split_to_tube_racks'
  end

  let(:user_uuid) { SecureRandom.uuid }
  let(:child_sequencing_tube_purpose_uuid) { SecureRandom.uuid }
  let(:child_sequencing_tube_purpose_name) { 'Seq Child Purpose' }
  let(:child_contingency_tube_purpose_uuid) { SecureRandom.uuid }
  let(:child_contingency_tube_purpose_name) { 'Spare Child Purpose' }
  let(:ancestor_tube_purpose_uuid) { SecureRandom.uuid }
  let(:ancestor_tube_purpose_name) { 'Ancestor Tube Purpose' }

  let(:parent_uuid) { SecureRandom.uuid }

  # The parent plate needs to have several wells containing the same sample

  # samples
  let(:sample1_uuid) { SecureRandom.uuid }
  let(:sample2_uuid) { SecureRandom.uuid }

  let(:sample1) { create(:v2_sample, name: 'Sample1', uuid: sample1_uuid) }
  let(:sample2) { create(:v2_sample, name: 'Sample2', uuid: sample2_uuid) }

  # submission requests
  let(:request_type) { create :request_type, key: 'rt_1' }
  let(:request_a) { create :library_request, request_type: request_type, uuid: 'request-a1', submission_id: '2' }
  let(:request_b) { create :library_request, request_type: request_type, uuid: 'request-a2', submission_id: '2' }
  let(:request_c) { create :library_request, request_type: request_type, uuid: 'request-a3', submission_id: '2' }
  let(:request_d) { create :library_request, request_type: request_type, uuid: 'request-b1', submission_id: '2' }
  let(:request_e) { create :library_request, request_type: request_type, uuid: 'request-b2', submission_id: '2' }

  # parent aliquots
  let(:parent_aliquot_sample1_aliquot1) { create(:v2_aliquot, sample: sample1, outer_request: request_a) }
  let(:parent_aliquot_sample1_aliquot2) { create(:v2_aliquot, sample: sample1, outer_request: request_b) }
  let(:parent_aliquot_sample1_aliquot3) { create(:v2_aliquot, sample: sample1, outer_request: request_c) }

  let(:parent_aliquot_sample2_aliquot1) { create(:v2_aliquot, sample: sample2, outer_request: request_d) }
  let(:parent_aliquot_sample2_aliquot2) { create(:v2_aliquot, sample: sample2, outer_request: request_e) }

  # parent well ancestor stock tubes
  let(:ancestor_tube_1_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:ancestor_tube_1_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: ancestor_tube_purpose_name,
      aliquots: [ancestor_tube_1_aliquot],
      barcode_number: 1
    )
  end

  let(:ancestor_2_aliquot) { create(:v2_aliquot, sample: sample2) }
  let(:ancestor_tube_2_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: ancestor_tube_purpose_name,
      aliquots: [ancestor_2_aliquot],
      barcode_number: 2
    )
  end

  # ancestor tubes list
  let(:ancestor_tubes) { [ancestor_tube_1_v2, ancestor_tube_2_v2] }

  # parent wells
  let(:parent_well_a1) do
    create(:v2_well, location: 'A1', aliquots: [parent_aliquot_sample1_aliquot1], state: 'passed')
  end
  let(:parent_well_a2) do
    create(:v2_well, location: 'A2', aliquots: [parent_aliquot_sample1_aliquot2], state: 'passed')
  end
  let(:parent_well_a3) do
    create(:v2_well, location: 'A3', aliquots: [parent_aliquot_sample1_aliquot3], state: 'passed')
  end

  let(:parent_well_b1) do
    create(:v2_well, location: 'B1', aliquots: [parent_aliquot_sample2_aliquot1], state: 'passed')
  end
  let(:parent_well_b2) do
    create(:v2_well, location: 'B2', aliquots: [parent_aliquot_sample2_aliquot2], state: 'passed')
  end

  # parent plate
  let(:parent_plate) do
    create(
      :v2_plate,
      uuid: parent_uuid,
      wells: [parent_well_a1, parent_well_a2, parent_well_a3, parent_well_b1, parent_well_b2],
      barcode_number: 6,
      ancestors: ancestor_tubes
    )
  end

  # parent plate v1 api
  let(:parent_v1) { json :plate_with_metadata, uuid: parent_uuid, barcode_number: 6, qc_files_actions: %w[read create] }

  # form attributes - required parameters for the labware creator
  let(:form_attributes) do
    { user_uuid: user_uuid, purpose_uuid: child_sequencing_tube_purpose_uuid, parent_uuid: parent_uuid }
  end

  # child tubes for lookup after creation
  let(:child_tube_1_uuid) { SecureRandom.uuid }
  let(:child_tube_1_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:child_tube_1_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_sequencing_tube_purpose_name,
      aliquots: [child_tube_1_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 1,
      uuid: child_tube_1_uuid
    )
  end

  let(:child_tube_2_uuid) { SecureRandom.uuid }
  let(:child_tube_2_aliquot) { create(:v2_aliquot, sample: sample2) }
  let(:child_tube_2_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_sequencing_tube_purpose_name,
      aliquots: [child_tube_2_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 2,
      uuid: child_tube_2_uuid
    )
  end

  let(:child_tube_3_uuid) { SecureRandom.uuid }
  let(:child_tube_3_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:child_tube_3_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_contingency_tube_purpose_name,
      aliquots: [child_tube_3_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 11,
      uuid: child_tube_3_uuid
    )
  end

  let(:child_tube_4_uuid) { SecureRandom.uuid }
  let(:child_tube_4_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:child_tube_4_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_contingency_tube_purpose_name,
      aliquots: [child_tube_4_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 12,
      uuid: child_tube_4_uuid
    )
  end

  let(:child_tube_5_uuid) { SecureRandom.uuid }
  let(:child_tube_5_aliquot) { create(:v2_aliquot, sample: sample2) }
  let(:child_tube_5_v2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_contingency_tube_purpose_name,
      aliquots: [child_tube_5_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 13,
      uuid: child_tube_5_uuid
    )
  end

  let(:sequencing_file) do
    fixture_file_upload(
      'spec/fixtures/files/scrna_core/scrna_core_sequencing_tube_rack_scan.csv',
      'sequencescape/qc_file'
    )
  end

  let(:contingency_file) do
    fixture_file_upload(
      'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan.csv',
      'sequencescape/qc_file'
    )
  end

  before do
    # need both child tubes to have a purpose config here
    create(
      :plate_split_to_tube_racks_purpose_config,
      name: child_sequencing_tube_purpose_name,
      uuid: child_sequencing_tube_purpose_uuid
    )
    create(
      :plate_split_to_tube_racks_purpose_config,
      name: child_contingency_tube_purpose_name,
      uuid: child_contingency_tube_purpose_uuid
    )

    # ancestor tube purpose config
    create(:purpose_config, name: ancestor_tube_purpose_name, uuid: ancestor_tube_purpose_uuid)

    # ancestor tube lookups
    stub_v2_tube(ancestor_tube_1_v2, stub_search: false)
    stub_v2_tube(ancestor_tube_2_v2, stub_search: false)

    # child tube lookups
    stub_v2_tube(child_tube_1_v2, stub_search: false)
    stub_v2_tube(child_tube_2_v2, stub_search: false)
    stub_v2_tube(child_tube_3_v2, stub_search: false)
    stub_v2_tube(child_tube_4_v2, stub_search: false)
    stub_v2_tube(child_tube_5_v2, stub_search: false)
  end

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PlateSplitToTubeRacks
    end
  end

  context '#must_have_correct_number_of_tubes_in_rack_files' do
    let(:num_parent_wells) { 96 }
    let(:num_parent_unique_samples) { 48 }
    let(:num_sequencing_tubes) { 48 }
    let(:num_contingency_tubes) { 48 }

    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.aliquots.sample,wells.downstream_tubes,' \
            'wells.downstream_tubes.custom_metadatum_collection'
      )
      allow(subject).to receive(:num_sequencing_tubes).and_return(num_sequencing_tubes)
      allow(subject).to receive(:num_contingency_tubes).and_return(num_contingency_tubes)
      allow(subject).to receive(:num_parent_wells).and_return(num_parent_wells)
      allow(subject).to receive(:num_parent_unique_samples).and_return(num_parent_unique_samples)
    end

    context 'when a contingency file is not present' do
      before { subject.validate }

      it 'does not call the validation' do
        expect(subject).not_to be_valid
        expect(subject).not_to receive(:must_have_correct_number_of_tubes_in_rack_files)
        expect(subject.errors.full_messages).to include("Sequencing file can't be blank")
      end
    end

    context 'when require_sequencing_tubes_only? is true' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file
        }
      end

      before do
        allow(subject).to receive(:require_sequencing_tubes_only?).and_return(true)
        subject.must_have_correct_number_of_tubes_in_rack_files
      end

      context 'when there are enough sequencing tubes' do
        let(:num_sequencing_tubes) { 48 }

        it 'is valid and does not create an error' do
          expect(subject.errors[:sequencing_csv_file]).to be_empty
        end
      end

      context 'when there are not enough contingency tubes' do
        let(:num_sequencing_tubes) { 47 }

        it 'is not valid and does create an error' do
          expect(subject.errors.full_messages).to include('Sequencing csv file contains insufficient tubes')
        end
      end

      context 'when there are too many contingency tubes' do
        let(:num_parent_wells) { 48 }
        let(:num_parent_unique_samples) { 24 }
        let(:num_contingency_tubes) { 0 }
        let(:num_sequencing_tubes) { 49 }

        it 'is not valid and does create an error' do
          expect(subject.errors.full_messages).to include('Sequencing csv file contains more tubes than needed')
        end
      end
    end

    context 'when require_sequencing_tubes_only? is false' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      before do
        allow(subject).to receive(:require_sequencing_tubes_only?).and_return(false)
        subject.must_have_correct_number_of_tubes_in_rack_files
      end

      context 'when there are enough tubes' do
        it 'is valid and does not create an error' do
          expect(subject.errors.full_messages).to be_empty
        end
      end

      context 'when there are not enough sequencing tubes' do
        let(:num_sequencing_tubes) { 47 }

        it 'is not valid and does create an error' do
          expect(subject.errors.full_messages).to include('Sequencing csv file contains insufficient tubes')
        end
      end

      context 'when there are too many sequencing tubes' do
        let(:num_sequencing_tubes) { 49 }

        it 'is not valid and does create an error' do
          expect(subject.errors.full_messages).to include('Sequencing csv file contains more tubes than needed')
        end
      end

      context 'when there are not enough contingency tubes' do
        let(:num_contingency_tubes) { 47 }

        it 'is not valid and does create an error' do
          expect(subject.errors.full_messages).to include('Contingency csv file contains insufficient tubes')
        end
      end

      context 'when there are too many contingency tubes' do
        let(:num_contingency_tubes) { 49 }

        it 'is not valid and does create an error' do
          expect(subject.errors.full_messages).to include('Contingency csv file contains more tubes than needed')
        end
      end
    end
  end

  context '#check_tube_rack_barcodes_differ_between_files' do
    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.aliquots.sample,wells.downstream_tubes,' \
            'wells.downstream_tubes.custom_metadatum_collection'
      )
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000001').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000002').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000011').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000012').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000013').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000014').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000015').and_return(nil)
    end

    context 'when files are not present' do
      before { subject.validate }

      it 'does not call the validation' do
        expect(subject).not_to be_valid
        expect(subject).not_to receive(:check_tube_rack_barcodes_differ_between_files)
        expect(subject.errors.full_messages).to include("Sequencing file can't be blank")
      end
    end

    context 'when a file is not correctly parsed' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      let(:sequencing_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_sequencing_tube_rack_scan_invalid.csv',
          'sequencescape/qc_file'
        )
      end

      before { subject.validate }

      it 'does not call the validation' do
        expect(subject).not_to be_valid
        expect(subject).not_to receive(:check_tube_rack_barcodes_differ_between_files)
        expect(subject.errors.full_messages).to include(
          'Sequencing csv file tube rack scan tube position contains an invalid coordinate, in row 1 [AAAA1]'
        )
      end
    end

    context 'when the files are the same' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: contingency_file,
          contingency_file: contingency_file
        }
      end

      let(:contingency_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan_3_tubes.csv',
          'sequencescape/qc_file'
        )
      end

      before { subject.validate }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:contingency_csv_file]).to include(
          'The tube rack barcodes within the contingency and sequencing files must be different'
        )
        expect(subject.errors[:contingency_csv_file]).to include(
          'Tube barcodes are duplicated across contingency and sequencing files (FX00000011, FX00000012, FX00000013)'
        )
        expect(subject.errors[:sequencing_csv_file]).to include('contains more tubes than needed')
      end
    end

    context 'when the tube rack barcodes are the same' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      let(:sequencing_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_sequencing_tube_rack_scan_duplicate_rack.csv',
          'sequencescape/qc_file'
        )
      end

      let(:contingency_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan_3_tubes.csv',
          'sequencescape/qc_file'
        )
      end

      before { subject.validate }

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:contingency_csv_file]).to include(
          'The tube rack barcodes within the contingency and sequencing files must be different'
        )
      end
    end
  end

  context '#check_tube_barcodes_differ_between_files' do
    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.aliquots.sample,wells.downstream_tubes,' \
            'wells.downstream_tubes.custom_metadatum_collection'
      )
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000001').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000002').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000011').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000012').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000013').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000014').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000015').and_return(nil)
    end

    context 'when files are not present' do
      before { subject.validate }

      it 'does not call the validation' do
        expect(subject).not_to be_valid
        expect(subject).not_to receive(:check_tube_barcodes_differ_between_files)
        expect(subject.errors.full_messages).to include("Sequencing file can't be blank")
      end
    end

    context 'when a file is not correctly parsed' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      let(:sequencing_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_sequencing_tube_rack_scan_invalid.csv',
          'sequencescape/qc_file'
        )
      end

      let(:contingency_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan_3_tubes.csv',
          'sequencescape/qc_file'
        )
      end

      before { subject.validate }

      it 'does not call the validation' do
        expect(subject).not_to be_valid
        expect(subject).not_to receive(:check_tube_barcodes_differ_between_files)
        expect(subject.errors.full_messages).to include(
          'Sequencing csv file tube rack scan tube position contains an invalid coordinate, in row 1 [AAAA1]'
        )
      end
    end

    context 'when there are duplicate tube barcodes between files' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end
      let(:seq_tube_details) do
        {
          'A1' => {
            'tube_rack_barcode' => 'TR00000001',
            'tube_barcode' => 'FX00000001'
          },
          'B1' => {
            'tube_rack_barcode' => 'TR00000001',
            'tube_barcode' => 'FX00000002'
          },
          'C1' => {
            'tube_rack_barcode' => 'TR00000001',
            'tube_barcode' => 'FX00000011'
          },
          'D1' => {
            'tube_rack_barcode' => 'TR00000001',
            'tube_barcode' => 'FX00000012'
          }
        }
      end

      before do
        allow(subject.sequencing_csv_file).to receive(:position_details).and_return(seq_tube_details)
        subject.validate
      end

      it 'is not valid' do
        expect(subject).not_to be_valid
        expect(subject.errors[:contingency_csv_file]).to include(
          'Tube barcodes are duplicated across contingency and sequencing files (FX00000011, FX00000012)'
        )
      end
    end
  end

  context '#check_tube_rack_scan_file' do
    let(:tube_rack_file) { double('tube_rack_file') } # don't need an actual file for this test
    let(:tube_posn) { 'A1' }
    let(:foreign_barcode) { '123456' }
    let(:tube_rack_barcode) { 'TR00000001' }
    let(:tube_details) { { 'tube_barcode' => foreign_barcode, 'tube_rack_barcode' => tube_rack_barcode } }
    let(:msg_prefix) { 'Sequencing' }
    let(:existing_tube) { create(:v2_tube, state: 'passed', barcode_number: 1, foreign_barcode: foreign_barcode) }

    before { allow(tube_rack_file).to receive(:position_details).and_return({ tube_posn => tube_details }) }

    context 'when the tube barcode already exists in the LIMS' do
      before do
        allow(Sequencescape::Api::V2::Tube).to receive(:find_by)
          .with(barcode: foreign_barcode)
          .and_return(existing_tube)
      end

      it 'adds an error to the errors collection' do
        subject.check_tube_rack_scan_file(tube_rack_file, msg_prefix)
        expect(subject.errors[:tube_rack_file]).to include(
          "#{msg_prefix} tube barcode #{foreign_barcode} (at rack position #{tube_posn}) already exists in the LIMS"
        )
      end
    end

    context 'when the tube barcode does not exist in the LIMS database' do
      before { allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: foreign_barcode).and_return(nil) }

      it 'does not add an error to the errors collection' do
        subject.check_tube_rack_scan_file(tube_rack_file, msg_prefix)
        expect(subject.errors[:tube_rack_file]).to be_empty
      end
    end
  end

  context '#save' do

    let!(:stub_sequencing_tube_creation_request_uuid) { SecureRandom.uuid }

    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.aliquots.sample,wells.downstream_tubes,' \
            'wells.downstream_tubes.custom_metadatum_collection'
      )
      stub_api_get(parent_uuid, body: parent_v1)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000001').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000002').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000011').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000012').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000013').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000014').and_return(nil)
      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000015').and_return(nil)
    end

    context 'with both sequencing and contingency files' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_sequencing_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      # stub the contingency tube creation
      let!(:stub_contingency_tube_creation_request_uuid) { SecureRandom.uuid }
      let!(:stub_contingency_tube_creation_request) do
        stub_api_post(
          'specific_tube_creations',
          payload: {
            specific_tube_creation: {
              child_purposes: [
                child_contingency_tube_purpose_uuid,
                child_contingency_tube_purpose_uuid,
                child_contingency_tube_purpose_uuid
              ],
              tube_attributes: [
                # sample 1 from well A2 to contingency tube 1 in A1
                { name: 'SPR:NT1O:A1', foreign_barcode: 'FX00000011' },
                # sample 2 from well B2 to contingency tube 2 in B1
                { name: 'SPR:NT2P:B1', foreign_barcode: 'FX00000012' },
                # sample 1 from well A3 to contingency tube 3 in C1
                { name: 'SPR:NT1O:C1', foreign_barcode: 'FX00000013' }
              ],
              user: user_uuid,
              parent: parent_uuid
            }
          },
          body: json(:specific_tube_creation, uuid: stub_contingency_tube_creation_request_uuid, children_count: 3)
        )
      end

      # stub what contingency tubes were just made
      let!(:stub_contingency_tube_creation_children_request) do
        stub_api_get(
          stub_contingency_tube_creation_request_uuid,
          'children',
          body:
            json(
              :tube_collection_with_barcodes_specified,
              size: 3,
              names: %w[SPR:NT1O:A1 SPR:NT2P:B1 SPR:NT1O:C1],
              barcode_prefix: 'FX',
              barcode_numbers: [11, 12, 13],
              uuid_index_offset: 2
            )
        )
      end

      # body for stubbing the contingency file upload
      let(:contingency_file_content) do
        content = contingency_file.read
        contingency_file.rewind
        content
      end

      # stub the contingency file upload
      let!(:stub_contingency_file_upload) do
        stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
          .with(
            body: contingency_file_content,
            headers: {
              'Content-Type' => 'sequencescape/qc_file',
              'Content-Disposition' => 'form-data; filename="scrna_core_contingency_tube_rack_scan.csv"'
            }
          )
          .to_return(
            status: 201,
            body: json(:qc_file, filename: 'scrna_core_contingency_tube_rack_scan.csv'),
            headers: {
              'content-type' => 'application/json'
            }
          )
      end

      # body for stubbing the sequencing file upload
      let(:sequencing_file_content) do
        content = sequencing_file.read
        sequencing_file.rewind
        content
      end

      # stub the sequencing file upload
      let!(:stub_sequencing_file_upload) do
        stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
          .with(
            body: sequencing_file_content,
            headers: {
              'Content-Type' => 'sequencescape/qc_file',
              'Content-Disposition' => 'form-data; filename="scrna_core_sequencing_tube_rack_scan.csv"'
            }
          )
          .to_return(
            status: 201,
            body: json(:qc_file, filename: 'scrna_core_sequencing_tube_rack_scan.csv'),
            headers: {
              'content-type' => 'application/json'
            }
          )
      end

      # stub the sequencing tube creation
      let!(:stub_sequencing_tube_creation_request_uuid) { SecureRandom.uuid }
      let!(:stub_sequencing_tube_creation_request) do
        stub_api_post(
          'specific_tube_creations',
          payload: {
            specific_tube_creation: {
              child_purposes: [child_sequencing_tube_purpose_uuid, child_sequencing_tube_purpose_uuid],
              tube_attributes: [
                # sample 1 in well A1 to seq tube 1 in A1
                { name: 'SEQ:NT1O:A1', foreign_barcode: 'FX00000001' },
                # sample 2 in well B1 to seq tube 2 in B1
                { name: 'SEQ:NT2P:B1', foreign_barcode: 'FX00000002' }
              ],
              user: user_uuid,
              parent: parent_uuid
            }
          },
          body: json(:specific_tube_creation, uuid: stub_sequencing_tube_creation_request_uuid, children_count: 2)
        )
      end

      # stub what sequencing tubes were just made
      let!(:stub_sequencing_tube_creation_children_request) do
        stub_api_get(
          stub_sequencing_tube_creation_request_uuid,
          'children',
          body:
            json(
              :tube_collection_with_barcodes_specified,
              size: 2,
              names: %w[SEQ:NT1O:A1 SEQ:NT2P:B1],
              barcode_prefix: 'FX',
              barcode_numbers: [1, 2]
            )
        )
      end

      # stub the transfer creation
      let!(:stub_transfer_creation_request) do
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: [
                { 'submission_id' => '2', 'source_asset' => parent_well_a1.uuid, 'target_asset' => 'tube-0' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b1.uuid, 'target_asset' => 'tube-1' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a2.uuid, 'target_asset' => 'tube-2' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b2.uuid, 'target_asset' => 'tube-3' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a3.uuid, 'target_asset' => 'tube-4' }
              ]
            }
          },
          body: '{}'
        )
      end

      # need api v1 versions of child tubes
      let(:child_tube_1_v1) { json :tube, uuid: child_tube_1_uuid, barcode_prefix: 'FX', barcode_number: 1 }
      let(:child_tube_2_v1) { json :tube, uuid: child_tube_2_uuid, barcode_prefix: 'FX', barcode_number: 2 }
      let(:child_tube_3_v1) { json :tube, uuid: child_tube_3_uuid, barcode_prefix: 'FX', barcode_number: 11 }
      let(:child_tube_4_v1) { json :tube, uuid: child_tube_4_uuid, barcode_prefix: 'FX', barcode_number: 12 }
      let(:child_tube_5_v1) { json :tube, uuid: child_tube_5_uuid, barcode_prefix: 'FX', barcode_number: 13 }

      # need to stub the creation of the tube metadata
      let!(:metadata_for_tube_1) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'A1' } }
      let!(:stub_create_metadata_for_tube_1) do
        stub_create_labware_metadata(
          child_tube_1_v2.barcode.machine,
          child_tube_1_v1,
          child_tube_1_uuid,
          user_uuid,
          metadata_for_tube_1
        )
      end

      let!(:metadata_for_tube_2) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'B1' } }
      let!(:stub_create_metadata_for_tube_2) do
        stub_create_labware_metadata(
          child_tube_2_v2.barcode.machine,
          child_tube_2_v1,
          child_tube_2_uuid,
          user_uuid,
          metadata_for_tube_2
        )
      end

      let!(:metadata_for_tube_3) { { tube_rack_barcode: 'TR00000002', tube_rack_position: 'A1' } }
      let!(:stub_create_metadata_for_tube_3) do
        stub_create_labware_metadata(
          child_tube_3_v2.barcode.machine,
          child_tube_3_v1,
          child_tube_3_uuid,
          user_uuid,
          metadata_for_tube_3
        )
      end

      let!(:metadata_for_tube_4) { { tube_rack_barcode: 'TR00000002', tube_rack_position: 'B1' } }
      let!(:stub_create_metadata_for_tube_4) do
        stub_create_labware_metadata(
          child_tube_4_v2.barcode.machine,
          child_tube_4_v1,
          child_tube_4_uuid,
          user_uuid,
          metadata_for_tube_4
        )
      end

      let!(:metadata_for_tube_5) { { tube_rack_barcode: 'TR00000002', tube_rack_position: 'C1' } }
      let!(:stub_create_metadata_for_tube_5) do
        stub_create_labware_metadata(
          child_tube_5_v2.barcode.machine,
          child_tube_5_v1,
          child_tube_5_uuid,
          user_uuid,
          metadata_for_tube_5
        )
      end

      let(:contingency_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan_3_tubes.csv',
          'sequencescape/qc_file'
        )
      end

      before do
        stub_get_labware_metadata(child_tube_1_v2.barcode.machine, child_tube_1_v1)
        stub_get_labware_metadata(child_tube_2_v2.barcode.machine, child_tube_2_v1)
        stub_get_labware_metadata(child_tube_3_v2.barcode.machine, child_tube_3_v1)
        stub_get_labware_metadata(child_tube_4_v2.barcode.machine, child_tube_4_v1)
        stub_get_labware_metadata(child_tube_5_v2.barcode.machine, child_tube_5_v1)

        stub_asset_search(child_tube_1_v2.barcode.machine, child_tube_1_v1)
        stub_asset_search(child_tube_2_v2.barcode.machine, child_tube_2_v1)
        stub_asset_search(child_tube_3_v2.barcode.machine, child_tube_3_v1)
        stub_asset_search(child_tube_4_v2.barcode.machine, child_tube_4_v1)
        stub_asset_search(child_tube_5_v2.barcode.machine, child_tube_5_v1)
      end

      it 'creates the child tubes' do
        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_sequencing_file_upload).to have_been_made.once
        expect(stub_sequencing_tube_creation_request).to have_been_made.once
        expect(stub_contingency_file_upload).to have_been_made.once
        expect(stub_contingency_tube_creation_request).to have_been_made.once
        expect(stub_transfer_creation_request).to have_been_made.once
        expect(stub_create_metadata_for_tube_1).to have_been_requested
        expect(stub_create_metadata_for_tube_2).to have_been_requested
        expect(stub_create_metadata_for_tube_3).to have_been_requested
        expect(stub_create_metadata_for_tube_4).to have_been_requested
        expect(stub_create_metadata_for_tube_5).to have_been_requested
      end

      context 'when a well has been failed' do
        # failing well A1
        let(:parent_well_a1) do
          create(:v2_well, location: 'A1', aliquots: [parent_aliquot_sample1_aliquot1], state: 'failed')
        end

        # as A1 is failed order of samples is changed
        let!(:stub_sequencing_tube_creation_request) do
          stub_api_post(
            'specific_tube_creations',
            payload: {
              specific_tube_creation: {
                child_purposes: [child_sequencing_tube_purpose_uuid, child_sequencing_tube_purpose_uuid],
                tube_attributes: [
                  # sample 2 in well B1 to seq tube 1 in A1
                  { name: 'SEQ:NT2P:A1', foreign_barcode: 'FX00000001' },
                  # sample 1 in well A2 to seq tube 2 in B1
                  { name: 'SEQ:NT1O:B1', foreign_barcode: 'FX00000002' }
                ],
                user: user_uuid,
                parent: parent_uuid
              }
            },
            body: json(:specific_tube_creation, uuid: stub_sequencing_tube_creation_request_uuid, children_count: 2)
          )
        end

        # stub what sequencing tubes were just made (order changed)
        let!(:stub_sequencing_tube_creation_children_request) do
          stub_api_get(
            stub_sequencing_tube_creation_request_uuid,
            'children',
            body:
              json(
                :tube_collection_with_barcodes_specified,
                size: 2,
                names: %w[SEQ:NT2P:A1 SEQ:NT1O:B1],
                barcode_prefix: 'FX',
                barcode_numbers: [1, 2]
              )
          )
        end

        # only 2 contingency tubes will be needed
        let!(:stub_contingency_tube_creation_request) do
          stub_api_post(
            'specific_tube_creations',
            payload: {
              specific_tube_creation: {
                child_purposes: [child_contingency_tube_purpose_uuid, child_contingency_tube_purpose_uuid],
                tube_attributes: [
                  # sample 2 from well B2 to contingency tube 1 in A1
                  { name: 'SPR:NT2P:A1', foreign_barcode: 'FX00000011' },
                  # sample 1 from well A3 to contingency tube 2 in B1
                  { name: 'SPR:NT1O:B1', foreign_barcode: 'FX00000012' }
                ],
                user: user_uuid,
                parent: parent_uuid
              }
            },
            body: json(:specific_tube_creation, uuid: stub_contingency_tube_creation_request_uuid, children_count: 3)
          )
        end

        # stub what contingency tubes were just made (just 2)
        let!(:stub_contingency_tube_creation_children_request) do
          stub_api_get(
            stub_contingency_tube_creation_request_uuid,
            'children',
            body:
              json(
                :tube_collection_with_barcodes_specified,
                size: 2,
                names: %w[SPR:NT2P:A1 SPR:NT1O:B1],
                barcode_prefix: 'FX',
                barcode_numbers: [11, 12],
                uuid_index_offset: 2
              )
          )
        end

        # one fewer transfer request
        let!(:stub_transfer_creation_request) do
          stub_api_post(
            'transfer_request_collections',
            payload: {
              transfer_request_collection: {
                user: user_uuid,
                transfer_requests: [
                  { 'submission_id' => '2', 'source_asset' => parent_well_b1.uuid, 'target_asset' => 'tube-0' },
                  { 'submission_id' => '2', 'source_asset' => parent_well_a2.uuid, 'target_asset' => 'tube-1' },
                  { 'submission_id' => '2', 'source_asset' => parent_well_b2.uuid, 'target_asset' => 'tube-2' },
                  { 'submission_id' => '2', 'source_asset' => parent_well_a3.uuid, 'target_asset' => 'tube-3' }
                ]
              }
            },
            body: '{}'
          )
        end

        let(:contingency_file) do
          fixture_file_upload(
            'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan_2_tubes.csv',
            'sequencescape/qc_file'
          )
        end

        before do
          stub_get_labware_metadata(child_tube_1_v2.barcode.machine, child_tube_1_v1)
          stub_get_labware_metadata(child_tube_2_v2.barcode.machine, child_tube_2_v1)
          stub_get_labware_metadata(child_tube_3_v2.barcode.machine, child_tube_3_v1)
          stub_get_labware_metadata(child_tube_4_v2.barcode.machine, child_tube_4_v1)

          stub_asset_search(child_tube_1_v2.barcode.machine, child_tube_1_v1)
          stub_asset_search(child_tube_2_v2.barcode.machine, child_tube_2_v1)
          stub_asset_search(child_tube_3_v2.barcode.machine, child_tube_3_v1)
          stub_asset_search(child_tube_4_v2.barcode.machine, child_tube_4_v1)
        end

        it 'does not create a tube for the failed well' do
          expect(subject.valid?).to be_truthy
          expect(subject.save).to be_truthy
          expect(stub_sequencing_file_upload).to have_been_made.once
          expect(stub_sequencing_tube_creation_request).to have_been_made.once
          expect(stub_contingency_file_upload).to have_been_made.once
          expect(stub_contingency_tube_creation_request).to have_been_made.once
          expect(stub_transfer_creation_request).to have_been_made.once
          expect(stub_create_metadata_for_tube_1).to have_been_requested
          expect(stub_create_metadata_for_tube_2).to have_been_requested
          expect(stub_create_metadata_for_tube_3).to have_been_requested
          expect(stub_create_metadata_for_tube_4).to have_been_requested

          expect(stub_create_metadata_for_tube_5).to_not have_been_requested
        end
      end
    end

    context 'with just a sequencing file' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_sequencing_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file
        }
      end

      let(:contingency_file) { nil }
      let(:sequencing_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_sequencing_tube_rack_scan.csv',
          'sequencescape/qc_file'
        )
      end

      # child tubes for lookup after creation
      let(:child_tube_1_v2) do
        create(
          :v2_stock_tube,
          state: 'passed',
          purpose_name: child_sequencing_tube_purpose_name,
          aliquots: [child_tube_1_aliquot],
          barcode_prefix: 'FX',
          barcode_number: 1,
          uuid: child_tube_1_uuid
        )
      end

      let(:child_tube_2_v2) do
        create(
          :v2_stock_tube,
          state: 'passed',
          purpose_name: child_sequencing_tube_purpose_name,
          aliquots: [child_tube_2_aliquot],
          barcode_prefix: 'FX',
          barcode_number: 2,
          uuid: child_tube_2_uuid
        )
      end

      let(:child_tube_3_v2) do
        create(
          :v2_stock_tube,
          state: 'passed',
          purpose_name: child_sequencing_tube_purpose_name,
          aliquots: [child_tube_3_aliquot],
          barcode_prefix: 'FX',
          barcode_number: 11,
          uuid: child_tube_3_uuid
        )
      end

      let(:child_tube_4_v2) do
        create(
          :v2_stock_tube,
          state: 'passed',
          purpose_name: child_sequencing_tube_purpose_name,
          aliquots: [child_tube_4_aliquot],
          barcode_prefix: 'FX',
          barcode_number: 12,
          uuid: child_tube_4_uuid
        )
      end

      let(:child_tube_5_v2) do
        create(
          :v2_stock_tube,
          state: 'passed',
          purpose_name: child_sequencing_tube_purpose_name,
          aliquots: [child_tube_5_aliquot],
          barcode_prefix: 'FX',
          barcode_number: 13,
          uuid: child_tube_5_uuid
        )
      end

      let!(:stub_sequencing_tube_creation_request_uuid) { SecureRandom.uuid }
      let!(:stub_sequencing_tube_creation_request) do
        stub_api_post(
          'specific_tube_creations',
          payload: {
            specific_tube_creation: {
              child_purposes: [child_sequencing_tube_purpose_uuid, child_sequencing_tube_purpose_uuid],
              tube_attributes: [
                # sample 1 in well A1 to seq tube 1 in A1
                { name: 'SEQ:NT1O:A1', foreign_barcode: 'FX00000001' },
                # sample 2 in well B1 to seq tube 2 in B1
                { name: 'SEQ:NT2P:B1', foreign_barcode: 'FX00000002' }
              ],
              user: user_uuid,
              parent: parent_uuid
            }
          },
          body: json(:specific_tube_creation, uuid: stub_sequencing_tube_creation_request_uuid, children_count: 2)
        )
      end

      # stub what sequencing tubes were just made
      let!(:stub_sequencing_tube_creation_children_request) do
        stub_api_get(
          stub_sequencing_tube_creation_request_uuid,
          'children',
          body:
            json(
              :tube_collection_with_barcodes_specified,
              size: 2,
              names: %w[SEQ:NT1O:A1 SEQ:NT2P:B1],
              barcode_prefix: 'FX',
              barcode_numbers: [1, 2]
            )
        )
      end

      # stub the transfer creation
      let!(:stub_transfer_creation_request) do
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: [
                { 'submission_id' => '2', 'source_asset' => parent_well_a1.uuid, 'target_asset' => 'tube-0' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b1.uuid, 'target_asset' => 'tube-1' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a2.uuid, 'target_asset' => 'tube-2' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b2.uuid, 'target_asset' => 'tube-3' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a3.uuid, 'target_asset' => 'tube-4' }
              ]
            }
          },
          body: '{}'
        )
      end

      # need api v1 versions of child tubes
      let(:child_tube_1_v1) { json :tube, uuid: child_tube_1_uuid, barcode_prefix: 'FX', barcode_number: 1 }
      let(:child_tube_2_v1) { json :tube, uuid: child_tube_2_uuid, barcode_prefix: 'FX', barcode_number: 2 }
      let(:child_tube_3_v1) { json :tube, uuid: child_tube_3_uuid, barcode_prefix: 'FX', barcode_number: 11 }
      let(:child_tube_4_v1) { json :tube, uuid: child_tube_4_uuid, barcode_prefix: 'FX', barcode_number: 12 }
      let(:child_tube_5_v1) { json :tube, uuid: child_tube_5_uuid, barcode_prefix: 'FX', barcode_number: 13 }

      # need to stub the creation of the tube metadata
      let!(:metadata_for_tube_1) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'A1' } }
      let!(:stub_create_metadata_for_tube_1) do
        stub_create_labware_metadata(
          child_tube_1_v2.barcode.machine,
          child_tube_1_v1,
          child_tube_1_uuid,
          user_uuid,
          metadata_for_tube_1
        )
      end

      let!(:metadata_for_tube_2) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'B1' } }
      let!(:stub_create_metadata_for_tube_2) do
        stub_create_labware_metadata(
          child_tube_2_v2.barcode.machine,
          child_tube_2_v1,
          child_tube_2_uuid,
          user_uuid,
          metadata_for_tube_2
        )
      end

      let!(:metadata_for_tube_3) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'C1' } }
      let!(:stub_create_metadata_for_tube_3) do
        stub_create_labware_metadata(
          child_tube_3_v2.barcode.machine,
          child_tube_3_v1,
          child_tube_3_uuid,
          user_uuid,
          metadata_for_tube_3
        )
      end

      let!(:metadata_for_tube_4) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'E1' } }
      let!(:stub_create_metadata_for_tube_4) do
        stub_create_labware_metadata(
          child_tube_4_v2.barcode.machine,
          child_tube_4_v1,
          child_tube_4_uuid,
          user_uuid,
          metadata_for_tube_4
        )
      end

      let!(:metadata_for_tube_5) { { tube_rack_barcode: 'TR00000001', tube_rack_position: 'F1' } }
      let!(:stub_create_metadata_for_tube_5) do
        stub_create_labware_metadata(
          child_tube_5_v2.barcode.machine,
          child_tube_5_v1,
          child_tube_5_uuid,
          user_uuid,
          metadata_for_tube_5
        )
      end

      # body for stubbing the sequencing file upload
      let(:sequencing_file_content) do
        content = sequencing_file.read
        sequencing_file.rewind
        content
      end

      # stub the sequencing file upload
      let!(:stub_sequencing_file_upload) do
        stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
          .with(
            body: sequencing_file_content,
            headers: {
              'Content-Type' => 'sequencescape/qc_file',
              'Content-Disposition' => 'form-data; filename="scrna_core_sequencing_tube_rack_scan.csv"'
            }
          )
          .to_return(
            status: 201,
            body: json(:qc_file, filename: 'scrna_core_sequencing_tube_rack_scan.csv'),
            headers: {
              'content-type' => 'application/json'
            }
          )
      end

      before do
        stub_get_labware_metadata(child_tube_1_v2.barcode.machine, child_tube_1_v1)
        stub_get_labware_metadata(child_tube_2_v2.barcode.machine, child_tube_2_v1)
        stub_get_labware_metadata(child_tube_3_v2.barcode.machine, child_tube_3_v1)
        stub_get_labware_metadata(child_tube_4_v2.barcode.machine, child_tube_4_v1)
        stub_get_labware_metadata(child_tube_5_v2.barcode.machine, child_tube_5_v1)

        stub_asset_search(child_tube_1_v2.barcode.machine, child_tube_1_v1)
        stub_asset_search(child_tube_2_v2.barcode.machine, child_tube_2_v1)
        stub_asset_search(child_tube_3_v2.barcode.machine, child_tube_3_v1)
        stub_asset_search(child_tube_4_v2.barcode.machine, child_tube_4_v1)
        stub_asset_search(child_tube_5_v2.barcode.machine, child_tube_5_v1)
      end

      it 'creates the child tubes' do
        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_sequencing_file_upload).to have_been_made.once
        expect(stub_sequencing_tube_creation_request).to have_been_made.once
        expect(stub_transfer_creation_request).to have_been_made.once
        expect(stub_create_metadata_for_tube_1).to have_been_requested
        expect(stub_create_metadata_for_tube_2).to have_been_requested
        expect(stub_create_metadata_for_tube_3).to have_been_requested
        expect(stub_create_metadata_for_tube_4).to have_been_requested
        expect(stub_create_metadata_for_tube_5).to have_been_requested
      end
    end
  end
end
