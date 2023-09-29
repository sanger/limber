# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::PlateSplitToTubeRacks, with: :uploader do
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
  let(:ancestor_1_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:ancestor_1_tube) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: ancestor_tube_purpose_name,
      aliquots: [ancestor_1_aliquot],
      barcode_number: 1
    )
  end

  let(:ancestor_2_aliquot) { create(:v2_aliquot, sample: sample2) }
  let(:ancestor_2_tube) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: ancestor_tube_purpose_name,
      aliquots: [ancestor_2_aliquot],
      barcode_number: 2
    )
  end

  # ancestor tubes list
  let(:ancestor_tubes) { [ancestor_1_tube, ancestor_2_tube] }

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
  let(:child_tube_sequencing_1_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:child_tube_sequencing_1) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_sequencing_tube_purpose_name,
      aliquots: [child_tube_sequencing_1_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 1
    )
  end

  let(:child_tube_sequencing_2_aliquot) { create(:v2_aliquot, sample: sample2) }
  let(:child_tube_sequencing_2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_sequencing_tube_purpose_name,
      aliquots: [child_tube_sequencing_2_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 2
    )
  end

  let(:child_tube_contingency_1_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:child_tube_contingency_1) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_contingency_tube_purpose_name,
      aliquots: [child_tube_contingency_1_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 11
    )
  end

  let(:child_tube_contingency_2_aliquot) { create(:v2_aliquot, sample: sample1) }
  let(:child_tube_contingency_2) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_contingency_tube_purpose_name,
      aliquots: [child_tube_contingency_2_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 12
    )
  end

  let(:child_tube_contingency_3_aliquot) { create(:v2_aliquot, sample: sample2) }
  let(:child_tube_contingency_3) do
    create(
      :v2_stock_tube,
      state: 'passed',
      purpose_name: child_contingency_tube_purpose_name,
      aliquots: [child_tube_contingency_3_aliquot],
      barcode_prefix: 'FX',
      barcode_number: 13
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
    stub_v2_tube(ancestor_1_tube, stub_search: false)
    stub_v2_tube(ancestor_2_tube, stub_search: false)

    # child tube lookups
    stub_v2_tube(child_tube_sequencing_1, stub_search: false)
    stub_v2_tube(child_tube_sequencing_2, stub_search: false)
    stub_v2_tube(child_tube_contingency_1, stub_search: false)
    stub_v2_tube(child_tube_contingency_2, stub_search: false)
    stub_v2_tube(child_tube_contingency_3, stub_search: false)
  end

  context 'on new' do
    has_a_working_api

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PlateSplitToTubeRacks
    end
  end

  context '#sufficient_tubes_in_racks?' do
    let(:num_parent_wells) { 96 }
    let(:num_parent_unique_samples) { 48 }
    let(:num_sequencing_tubes) { 48 }
    let(:num_contingency_tubes) { 48 }

    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'
      )
      allow(subject).to receive(:num_sequencing_tubes).and_return(num_sequencing_tubes)
      allow(subject).to receive(:num_contingency_tubes).and_return(num_contingency_tubes)
    end

    context 'when require_contingency_tubes_only? is true' do
      before { allow(subject).to receive(:require_contingency_tubes_only?).and_return(true) }

      context 'when there are enough contingency tubes' do
        let(:num_contingency_tubes) { 96 }

        it 'returns true' do
          expect(subject.sufficient_tubes_in_racks?).to be true
        end
      end

      context 'when there are not enough contingency tubes' do
        let(:num_contingency_tubes) { 47 }

        it 'returns false' do
          expect(subject.sufficient_tubes_in_racks?).to be false
        end
      end
    end

    context 'when require_contingency_tubes_only? is false' do
      before { allow(subject).to receive(:require_contingency_tubes_only?).and_return(false) }

      context 'when there are enough tubes' do
        it 'returns true' do
          expect(subject.sufficient_tubes_in_racks?).to be true
        end
      end

      context 'when there are not enough sequencing tubes' do
        let(:num_sequencing_tubes) { 47 }

        it 'returns false' do
          expect(subject.sufficient_tubes_in_racks?).to be false
        end
      end

      context 'when there are not enough contingency tubes' do
        let(:num_contingency_tubes) { 47 }

        it 'returns false' do
          expect(subject.sufficient_tubes_in_racks?).to be false
        end
      end
    end
  end

  context '#check_tube_rack_scan_file' do
    let(:tube_rack_file) { double('tube_rack_file') } # don't need an actual file for this test
    let(:tube_posn) { 'A1' }
    let(:foreign_barcode) { '123456' }
    let(:tube_details) { { 'barcode' => foreign_barcode } }
    let(:msg_prefix) { 'Sequencing' }
    let(:existing_tube) { create(:v2_tube, state: 'passed', barcode_number: 1, foreign_barcode: foreign_barcode) }

    before { allow(tube_rack_file).to receive(:position_details).and_return({ tube_posn => tube_details }) }

    context 'when the tube barcode already exists in the LIMS' do
      before do
        allow(Sequencescape::Api::V2::Tube).to receive(:find_by)
          .with(barcode: foreign_barcode)
          .and_return(existing_tube)
      end

      has_a_working_api

      it 'adds an error to the errors collection' do
        subject.check_tube_rack_scan_file(tube_rack_file, msg_prefix)
        expect(subject.errors[:tube_rack_file]).to include(
          "#{msg_prefix} tube barcode #{foreign_barcode} (at rack position #{tube_posn}) already exists in the LIMS"
        )
      end
    end

    context 'when the tube barcode does not exist in the LIMS database' do
      before { allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: foreign_barcode).and_return(nil) }

      has_a_working_api

      it 'does not add an error to the errors collection' do
        subject.check_tube_rack_scan_file(tube_rack_file, msg_prefix)
        expect(subject.errors[:tube_rack_file]).to be_empty
      end
    end
  end

  context '#save' do
    has_a_working_api

    # body for stubbing the contingency file upload
    let(:contingency_file_content) do
      content = contingency_file.read
      contingency_file.rewind
      content
    end

    # stub the contingency file upload
    let(:stub_contingency_file_upload) do
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

    # stub the contingency tube creation
    let(:stub_contingency_tube_creation_request_uuid) { SecureRandom.uuid }

    let(:stub_contingency_tube_creation_request) do
      stub_api_post(
        'specific_tube_creations',
        payload: {
          specific_tube_creation: {
            child_purposes: [
              child_contingency_tube_purpose_uuid,
              child_contingency_tube_purpose_uuid,
              child_contingency_tube_purpose_uuid
            ],
            # TODO: how are the tubes named if multiple racks?
            # TODO: we could prefix with rack barcode
            tube_attributes: [
              # sample 1 from well A2 to contingency tube 1 in A1
              { name: 'SPR:NT1O:A1', foreign_barcode: 'FX00000011' },
              # sample 1 from well A3 to contingency tube 2 in B1
              { name: 'SPR:NT1O:B1', foreign_barcode: 'FX00000012' },
              # sample 2 from well B2 to contingency tube 3 in C1
              { name: 'SPR:NT2P:C1', foreign_barcode: 'FX00000013' }
            ],
            user: user_uuid,
            parent: parent_uuid
          }
        },
        body: json(:specific_tube_creation, uuid: stub_contingency_tube_creation_request_uuid, children_count: 3)
      )
    end

    # stub what contingency tubes were just made
    let(:stub_contingency_tube_creation_children_request) do
      stub_api_get(
        stub_contingency_tube_creation_request_uuid,
        'children',
        body: json(:tube_collection, size: 3, names: %w[SPR:NT1O:A1 SPR:NT1O:B1 SPR:NT2P:C1])
      )
    end

    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'
      )

      # stub_sequencing_file_upload
      stub_contingency_file_upload

      # stub_sequencing_tube_creation_children_request
      # stub_sequencing_tube_creation_request
      stub_contingency_tube_creation_children_request
      stub_contingency_tube_creation_request
      stub_transfer_creation_request
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
      let(:sequencing_file) do
        fixture_file_upload('spec/fixtures/files/scrna_core_sequencing_tube_rack_scan.csv', 'sequencescape/qc_file')
      end

      let(:contingency_file) do
        fixture_file_upload('spec/fixtures/files/scrna_core_contingency_tube_rack_scan.csv', 'sequencescape/qc_file')
      end

      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_sequencing_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      # body for stubbing the sequencing file upload
      let(:sequencing_file_content) do
        content = sequencing_file.read
        sequencing_file.rewind
        content
      end

      # stub the sequencing file upload
      let(:stub_sequencing_file_upload) do
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
      let(:stub_sequencing_tube_creation_request_uuid) { SecureRandom.uuid }
      let(:stub_sequencing_tube_creation_request) do
        stub_api_post(
          'specific_tube_creations',
          payload: {
            specific_tube_creation: {
              child_purposes: [child_sequencing_tube_purpose_uuid, child_sequencing_tube_purpose_uuid],
              # TODO: how are the tubes named if multiple racks?
              # TODO: we could prefix with rack barcode
              tube_attributes: [
                { name: 'SEQ:NT1O:A1', foreign_barcode: 'FX00000001' }, # sample 1 in well A1 to seq tube 1 in A1
                { name: 'SEQ:NT2P:B1', foreign_barcode: 'FX00000002' } # sample 2 in well B1 to seq tube 2 in B1
              ],
              user: user_uuid,
              parent: parent_uuid
            }
          },
          body: json(:specific_tube_creation, uuid: stub_sequencing_tube_creation_request_uuid, children_count: 2)
        )
      end

      # stub what sequencing tubes were just made
      let(:stub_sequencing_tube_creation_children_request) do
        stub_api_get(
          stub_sequencing_tube_creation_request_uuid,
          'children',
          body: json(:tube_collection, size: 2, names: %w[SEQ:NT1O:A1 SEQ:NT2P:B1])
        )
      end

      # stub the transfer creation
      let(:stub_transfer_creation_request) do
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: [
                { 'submission_id' => '2', 'source_asset' => parent_well_a1.uuid, 'target_asset' => 'tube-0' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a2.uuid, 'target_asset' => 'tube-0' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a3.uuid, 'target_asset' => 'tube-1' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b1.uuid, 'target_asset' => 'tube-1' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b2.uuid, 'target_asset' => 'tube-2' }
              ]
            }
          },
          body: '{}'
        )
      end

      before do
        stub_sequencing_file_upload
        stub_sequencing_tube_creation_children_request
        stub_sequencing_tube_creation_request
      end

      it 'creates the child tubes' do
        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_sequencing_file_upload).to have_been_made.once
        expect(stub_sequencing_tube_creation_request).to have_been_made.once
        expect(stub_contingency_file_upload).to have_been_made.once
        expect(stub_contingency_tube_creation_request).to have_been_made.once
        expect(stub_transfer_creation_request).to have_been_made.once
      end
    end

    context 'with just a contingency file' do
      let(:sequencing_file) { nil }

      let(:contingency_file) do
        fixture_file_upload('spec/fixtures/files/scrna_core_contingency_tube_rack_scan.csv', 'sequencescape/qc_file')
      end

      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_contingency_tube_purpose_uuid,
          parent_uuid: parent_uuid,
          contingency_file: contingency_file
        }
      end

      let(:stub_contingency_tube_creation_request) do
        stub_api_post(
          'specific_tube_creations',
          payload: {
            specific_tube_creation: {
              child_purposes: [
                child_contingency_tube_purpose_uuid,
                child_contingency_tube_purpose_uuid,
                child_contingency_tube_purpose_uuid,
                child_contingency_tube_purpose_uuid,
                child_contingency_tube_purpose_uuid
              ],
              # TODO: how are the tubes named if multiple racks?
              # TODO: we could prefix with rack barcode
              tube_attributes: [
                # sample 1 from well A1 to contingency tube 1 in A1
                { name: 'SPR:NT1O:A1', foreign_barcode: 'FX00000011' },
                # sample 1 from well A2 to contingency tube 2 in B1
                { name: 'SPR:NT1O:B1', foreign_barcode: 'FX00000012' },
                # sample 1 from well A3 to contingency tube 3 in C1
                { name: 'SPR:NT1O:C1', foreign_barcode: 'FX00000013' },
                # sample 2 from well B1 to contingency tube 4 in E1 (D1 set as NO READ)
                { name: 'SPR:NT2P:E1', foreign_barcode: 'FX00000014' },
                # sample 2 from well B2 to contingency tube 5 in F1
                { name: 'SPR:NT2P:F1', foreign_barcode: 'FX00000015' }
              ],
              user: user_uuid,
              parent: parent_uuid
            }
          },
          body: json(:specific_tube_creation, uuid: stub_contingency_tube_creation_request_uuid, children_count: 5)
        )
      end

      # stub what contingency tubes were just made
      let(:stub_contingency_tube_creation_children_request) do
        stub_api_get(
          stub_contingency_tube_creation_request_uuid,
          'children',
          body: json(:tube_collection, size: 5, names: %w[SPR:NT1O:A1 SPR:NT1O:B1 SPR:NT1O:C1 SPR:NT2P:E1 SPR:NT2P:F1])
        )
      end

      # stub the transfer creation
      let(:stub_transfer_creation_request) do
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: [
                { 'submission_id' => '2', 'source_asset' => parent_well_a1.uuid, 'target_asset' => 'tube-0' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a2.uuid, 'target_asset' => 'tube-1' },
                { 'submission_id' => '2', 'source_asset' => parent_well_a3.uuid, 'target_asset' => 'tube-2' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b1.uuid, 'target_asset' => 'tube-3' },
                { 'submission_id' => '2', 'source_asset' => parent_well_b2.uuid, 'target_asset' => 'tube-4' }
              ]
            }
          },
          body: '{}'
        )
      end

      it 'creates the child tubes' do
        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_contingency_file_upload).to have_been_made.once
        expect(stub_contingency_tube_creation_request).to have_been_made.once
        expect(stub_transfer_creation_request).to have_been_made.once
      end
    end
  end
end
