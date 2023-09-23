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

  # parent aliquots
  let(:parent_aliquot_sample1_aliquot1) { create(:v2_aliquot, sample: sample1) }
  let(:parent_aliquot_sample1_aliquot2) { create(:v2_aliquot, sample: sample1) }
  let(:parent_aliquot_sample1_aliquot3) { create(:v2_aliquot, sample: sample1) }

  let(:parent_aliquot_sample2_aliquot1) { create(:v2_aliquot, sample: sample2) }
  let(:parent_aliquot_sample2_aliquot2) { create(:v2_aliquot, sample: sample2) }

  # let(:parent_aliquot_sample2_aliquot3) { create(:v2_aliquot, sample: sample1) }

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

  let(:form_attributes) do
    { user_uuid: user_uuid, purpose_uuid: child_sequencing_tube_purpose_uuid, parent_uuid: parent_uuid }
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
  end

  context 'on new' do
    has_a_working_api

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::PlateSplitToTubeRacks
    end
  end

  context '#save' do
    has_a_working_api

    let(:sequencing_file_content) do
      content = sequencing_file.read
      sequencing_file.rewind
      content
    end

    let(:contingency_file_content) do
      content = contingency_file.read
      contingency_file.rewind
      content
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

    # stub the sequencing file upload
    let(:stub_sequencing_file_upload) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
        .with(
          body: sequencing_file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="scrna_core_seq_tube_rack_scan.csv"'
          }
        )
        .to_return(
          status: 201,
          body: json(:qc_file, filename: 'scrna_core_seq_tube_rack_scan.csv'),
          headers: {
            'content-type' => 'application/json'
          }
        )
    end

    # stub the contingency file upload
    let(:stub_contingency_file_upload) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files'))
        .with(
          body: contingency_file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="scrna_core_cont_tube_rack_scan.csv"'
          }
        )
        .to_return(
          status: 201,
          body: json(:qc_file, filename: 'scrna_core_cont_tube_rack_scan.csv'),
          headers: {
            'content-type' => 'application/json'
          }
        )
    end

    # stub the sequencing tube creation
    let(:sequencing_tube_creation_request_uuid) { SecureRandom.uuid }

    let(:sequencing_tube_creation_request) do
      stub_api_post(
        'specific_tube_creations',
        payload: {
          specific_tube_creation: {
            child_purposes: [child_sequencing_tube_purpose_uuid, child_sequencing_tube_purpose_uuid],
            # TODO: how are the tubes named if multiple racks?
            # TODO: we could prefix with rack barcode
            tube_attributes: [
              { name: 'SEQ:NT1O:A1', foreign_barcode: 'AB10000001' }, # sample 1 in well A1 to seq tube 1 in A1
              { name: 'SEQ:NT2P:B1', foreign_barcode: 'AB10000002' } # sample 2 in well B1 to seq tube 2 in B1
            ],
            user: user_uuid,
            parent: parent_uuid
          }
        },
        body: json(:specific_tube_creation, uuid: sequencing_tube_creation_request_uuid, children_count: 2)
      )
    end

    # stub the contingency tube creation
    let(:contingency_tube_creation_request_uuid) { SecureRandom.uuid }

    let(:contingency_tube_creation_request) do
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
              { name: 'SPARE:NT1O:A1', foreign_barcode: 'AB20000001' },
              # sample 1 from well A3 to contingency tube 2 in B1
              { name: 'SPARE:NT1O:B1', foreign_barcode: 'AB20000002' },
              # sample 2 from well B2 to contingency tube 3 in C1
              { name: 'SPARE:NT2P:C1', foreign_barcode: 'AB20000003' }
            ],
            user: user_uuid,
            parent: parent_uuid
          }
        },
        body: json(:specific_tube_creation, uuid: contingency_tube_creation_request_uuid, children_count: 3)
      )
    end

    # stub what sequencing tubes were just made
    let(:sequencing_tube_creation_children_request) do
      stub_api_get(
        sequencing_tube_creation_request_uuid,
        'children',
        body: json(:tube_collection, names: %w[SEQ:NT1O:A1 SEQ:NT2P:B1])
      )
    end

    # stub what contingency tubes were just made
    let(:contingency_tube_creation_children_request) do
      stub_api_get(
        contingency_tube_creation_request_uuid,
        'children',
        body: json(:tube_collection, names: %w[SPARE:NT1O:A1 SPARE:NT1O:B1 SPARE:NT2P:C1])
      )
    end

    # let(:stub_parent_request) do
    #   stub_api_get(parent_uuid, body: parent_json)
    #   stub_api_get(parent_uuid, 'wells', body: wells_json)
    # end

    let(:transfer_creation_request) do
      stub_api_post(
        'transfer_request_collections',
        payload: {
          transfer_request_collection: {
            user: user_uuid,
            transfer_requests: [
              # TODO: destination assets are not correct here
              { 'source_asset' => parent_well_a1.uuid, 'target_asset' => 'tube-0' },
              { 'source_asset' => parent_well_a2.uuid, 'target_asset' => 'tube-1' },
              { 'source_asset' => parent_well_a3.uuid, 'target_asset' => 'tube-2' },
              { 'source_asset' => parent_well_b1.uuid, 'target_asset' => 'tube-3' },
              { 'source_asset' => parent_well_b2.uuid, 'target_asset' => 'tube-4' }
            ]
          }
        },
        body: '{}'
      )
    end

    before do
      # stub_parent_request
      # stub_v2_plate(parent_plate, stub_search: false)
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'
      )
      stub_sequencing_file_upload
      stub_contingency_file_upload
      sequencing_tube_creation_children_request
      contingency_tube_creation_children_request
      sequencing_tube_creation_request
      contingency_tube_creation_request
      transfer_creation_request
    end

    context 'with valid files' do
      let(:sequencing_file) do
        fixture_file_upload('spec/fixtures/files/scrna_core_sequencing_tube_rack_scan.csv', 'sequencescape/qc_file')
      end

      let(:contingency_file) do
        fixture_file_upload('spec/fixtures/files/scrna_core_contingency_tube_rack_scan.csv', 'sequencescape/qc_file')
      end

      it 'works' do
        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_sequencing_file_upload).to have_been_made.once
        expect(stub_contingency_file_upload).to have_been_made.once
        expect(tube_creation_request).to have_been_made.once
        expect(transfer_creation_request).to have_been_made.once
      end
    end
  end
end
