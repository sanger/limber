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

  let(:user) { create :user }
  let(:user_uuid) { user.uuid }

  # child tube rack and tube details
  let(:child_sequencing_tube_purpose_name) { 'SEQ Tube Purpose' }
  let(:child_sequencing_tube_purpose_uuid) { SecureRandom.uuid }
  let(:child_sequencing_tube_rack_purpose_uuid) { SecureRandom.uuid }
  let(:child_sequencing_tube_rack_purpose_name) { 'SEQ TubeRack Purpose' }
  let(:child_sequencing_tube_rack_name) { 'SEQ Tube Rack' }
  let(:child_sequencing_tube_rack_barcode) { 'TR00000001' }

  let(:child_contingency_tube_purpose_name) { 'SPR Tube Purpose' }
  let(:child_contingency_tube_purpose_uuid) { SecureRandom.uuid }
  let(:child_contingency_tube_rack_purpose_uuid) { SecureRandom.uuid }
  let(:child_contingency_tube_rack_purpose_name) { 'SPR TubeRack Purpose' }
  let(:child_contingency_tube_rack_name) { 'SPR Tube Rack' }
  let(:child_contingency_tube_rack_barcode) { 'TR00000002' }

  # ancestor tube details
  let(:ancestor_tube_purpose_uuid) { SecureRandom.uuid }
  let(:ancestor_tube_purpose_name) { 'Ancestor Tube Purpose' }

  # parent plate details
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
    { user_uuid: user_uuid, purpose_uuid: child_sequencing_tube_rack_purpose_uuid, parent_uuid: parent_uuid }
  end

  # files
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

  # coordinates of tubes in racks (matches files being uploaded)
  let(:sequencing_file_coords) { %w[A1 B1] }
  let(:contingency_file_coords) { %w[A1 B1 C1 E1 F1] }

  # tube racks
  let(:sequencing_tube_rack) do
    create(
      :tube_rack,
      name: child_sequencing_tube_rack_name,
      labware_barcode: {
        ean13_barcode: child_sequencing_tube_rack_barcode,
        human_barcode: child_sequencing_tube_rack_barcode,
        machine_barcode: child_sequencing_tube_rack_barcode
      },
      purpose_name: child_sequencing_tube_rack_purpose_name,
      purpose_uuid: child_sequencing_tube_rack_purpose_uuid
    )
  end

  let(:contingency_tube_rack) do
    create(
      :tube_rack,
      name: child_contingency_tube_rack_name,
      labware_barcode: {
        ean13_barcode: child_contingency_tube_rack_barcode,
        human_barcode: child_contingency_tube_rack_barcode,
        machine_barcode: child_contingency_tube_rack_barcode
      },
      purpose_name: child_contingency_tube_rack_purpose_name,
      purpose_uuid: child_contingency_tube_rack_purpose_uuid
    )
  end

  # Prepare child tubes and stub their lookups and those of their racked_tubes.
  # tube_attributes should be an array of hashes with the tube name and foreign barcode.
  # [
  #   { name: 'SPR:NT1O:A1', foreign_barcode: 'FX00000011' }
  #   etc...
  # ]
  # rubocop:disable Metrics/MethodLength
  def prepare_created_child_tubes(tube_attributes, tube_rack)
    tube_attributes.map do |tube_attrs|
      tube_coordinate = tube_attrs[:name].split(':').last

      # create the tube
      child_tube =
        create(
          :v2_tube,
          name: tube_attrs[:name],
          purpose_uuid: tube_attrs[:purpose_uuid],
          purpose_name: tube_attrs[:purpose_name],
          barcode_prefix: 'FX',
          barcode_number: tube_attrs[:barcode_number],
          foreign_barcode: tube_attrs[:foreign_barcode]
        )

      # stub the tube
      stub_v2_labware(child_tube)

      # create the racked tube
      racked_tube = create(:racked_tube, tube: child_tube, tube_rack: tube_rack, coordinate: tube_coordinate)

      # stub the racked tube
      stub_v2_racked_tube(racked_tube)

      child_tube
    end
  end

  # rubocop:enable Metrics/MethodLength

  # Generate the attributes for the child tube racks.
  # Example output
  # [
  #   {
  #     :tube_rack_name=>"Seq Tube Rack",
  #     :tube_rack_barcode=>"TR00000001",
  #     :tube_rack_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
  #     :tube_rack_metadata_key=>"tube_rack_barcode",
  #     :racked_tubes=>[
  #       {
  #         :tube_barcode=>"SQ45303801",
  #         :tube_name=>"SEQ:NT749R:A1",
  #         :tube_purpose_uuid=>"0ab4c9cc-4dad-11ef-8ca3-82c61098d1a1",
  #         :tube_position=>"A1",
  #         :parent_uuids=>["bd49e7f8-80a1-11ef-bab6-82c61098d1a0"]
  #       },
  #       etc... more tubes
  #     ]
  #   },
  #   etc... second rack for contingency tubes
  # ]
  # Example input
  # params = {
  #  sequencing_tubes: [ array of v2_tube objects ],
  #  sequencing_tube_parent_well_uuids: [array of parent well uuids],
  #  contingency_tubes: [array of v2 tubes],
  #  contingency_tube_parent_well_uuids: [array of parent well uuids],
  # }
  # rubocop:disable Metrics/AbcSize
  def generate_child_tube_rack_attributes(params)
    tr_attributes = []
    if params[:sequencing_tubes].present?
      tr_attributes << {
        tube_rack_name: child_sequencing_tube_rack_name,
        tube_rack_barcode: sequencing_tube_rack.labware_barcode.human,
        tube_rack_purpose_uuid: child_sequencing_tube_rack_purpose_uuid,
        tube_rack_metadata_key: 'tube_rack_barcode',
        racked_tubes:
          params[:sequencing_tubes].each_with_index.map do |tube, tube_index|
            {
              tube_barcode: tube.foreign_barcode,
              tube_name: tube.name,
              tube_purpose_uuid: tube.purpose.uuid,
              tube_position: tube.name.split(':').last,
              parent_uuids: [params[:sequencing_tube_parent_well_uuids][tube_index]]
            }
          end
      }
    end

    if params[:contingency_tubes].present?
      tr_attributes << {
        tube_rack_name: child_contingency_tube_rack_name,
        tube_rack_barcode: contingency_tube_rack.labware_barcode.human,
        tube_rack_purpose_uuid: child_contingency_tube_rack_purpose_uuid,
        tube_rack_metadata_key: 'tube_rack_barcode',
        racked_tubes:
          params[:contingency_tubes].each_with_index.map do |tube, tube_index|
            {
              tube_barcode: tube.foreign_barcode,
              tube_name: tube.name,
              tube_purpose_uuid: tube.purpose.uuid,
              tube_position: tube.name.split(':').last,
              parent_uuids: [params[:contingency_tube_parent_well_uuids][tube_index]]
            }
          end
      }
    end

    tr_attributes
  end

  # rubocop:enable Metrics/AbcSize

  # {
  #   <barcode>: <uuid>,
  #   etc.
  # }
  def generate_tube_uuids_by_barcode
    (sequencing_tubes + contingency_tubes).each_with_object({}) { |tube, hash| hash[tube.foreign_barcode] = tube.uuid }
  end

  # Endpoint returns child tube rack objects
  def expect_specific_tube_rack_creation(child_tube_racks, child_tube_rack_attributes)
    # set up method override to get created child tube uuids by barcode
    allow(subject).to receive(:tube_uuids_by_barcode).and_return(generate_tube_uuids_by_barcode)

    # Create a mock for the specific tube rack creation in Sequencescape.
    specific_tube_rack_creation = double
    allow(specific_tube_rack_creation).to receive(:children).and_return(child_tube_racks)

    # Expect the post request and return the mock.
    expect_api_v2_posts(
      'SpecificTubeRackCreation',
      [{ parent_uuids: [parent_uuid], tube_rack_attributes: child_tube_rack_attributes, user_uuid: user_uuid }],
      [specific_tube_rack_creation]
    )
  end

  before do
    # set up the child tube rack purpose configs in the Settings
    create(
      :plate_split_to_tube_racks_purpose_config,
      name: child_sequencing_tube_rack_purpose_name,
      uuid: child_sequencing_tube_rack_purpose_uuid
    )
    create(
      :plate_split_to_tube_racks_purpose_config,
      name: child_contingency_tube_rack_purpose_name,
      uuid: child_contingency_tube_rack_purpose_uuid
    )

    # stub the tube rack purposes
    stub_v2_tube_rack_purpose(sequencing_tube_rack.purpose)
    stub_v2_tube_rack_purpose(contingency_tube_rack.purpose)

    # stub the child tube racks
    stub_v2_labware(sequencing_tube_rack)
    stub_v2_labware(contingency_tube_rack)

    # set up the child tube purposes
    create(:purpose_config, name: child_sequencing_tube_purpose_name, uuid: child_sequencing_tube_purpose_uuid)
    create(:purpose_config, name: child_contingency_tube_purpose_name, uuid: child_contingency_tube_purpose_uuid)

    # ancestor tube purpose config
    create(:purpose_config, name: ancestor_tube_purpose_name, uuid: ancestor_tube_purpose_uuid)

    # ancestor tube lookups
    stub_v2_tube(ancestor_tube_1_v2, stub_search: false)
    stub_v2_tube(ancestor_tube_2_v2, stub_search: false)

    # Block finding tubes by given barcodes.
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000001').and_return(nil)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000002').and_return(nil)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000011').and_return(nil)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000012').and_return(nil)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000013').and_return(nil)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000014').and_return(nil)
    allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: 'FX00000015').and_return(nil)
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
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
          purpose_uuid: child_contingency_tube_rack_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end
      let(:seq_tube_details) do
        {
          'A1' => {
            'tube_rack_barcode' => child_sequencing_tube_rack_barcode,
            'tube_barcode' => 'FX00000001'
          },
          'B1' => {
            'tube_rack_barcode' => child_sequencing_tube_rack_barcode,
            'tube_barcode' => 'FX00000002'
          },
          'C1' => {
            'tube_rack_barcode' => child_sequencing_tube_rack_barcode,
            'tube_barcode' => 'FX00000011'
          },
          'D1' => {
            'tube_rack_barcode' => child_sequencing_tube_rack_barcode,
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
    let(:tube_rack_barcode) { child_sequencing_tube_rack_barcode }
    let(:tube_details) { { 'tube_barcode' => foreign_barcode, 'tube_rack_barcode' => tube_rack_barcode } }
    let(:msg_prefix) { 'Sequencing' }
    let(:existing_tube) { create(:v2_tube, state: 'passed', barcode_number: 1, foreign_barcode: foreign_barcode) }

    before { allow(tube_rack_file).to receive(:position_details).and_return({ tube_posn => tube_details }) }

    context 'when the tube barcode already exists in the LIMS' do
      before do
        allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(barcode: foreign_barcode).and_return(
          existing_tube
        )
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
    # body for stubbing the contingency file upload
    let(:contingency_file_content) do
      content = contingency_file.read
      contingency_file.rewind
      content
    end

    # stub the contingency file upload
    let!(:stub_contingency_file_upload) do
      stub_request(:post, api_url_for(parent_uuid, 'qc_files')).with(
        body: contingency_file_content,
        headers: {
          'Content-Type' => 'sequencescape/qc_file',
          'Content-Disposition' => 'form-data; filename="scrna_core_contingency_tube_rack_scan.csv"'
        }
      ).to_return(
        status: 201,
        body: json(:qc_file, filename: 'scrna_core_contingency_tube_rack_scan.csv'),
        headers: {
          'content-type' => 'application/json'
        }
      )
    end

    # create the contingency tubes
    let(:contingency_tubes) do
      prepare_created_child_tubes(
        [
          # sample 1 from well A2 to contingency tube 1 in A1
          {
            name: 'SPR:NT1O:A1',
            foreign_barcode: 'FX00000011',
            barcode_number: 11,
            purpose_uuid: child_contingency_tube_purpose_uuid,
            purpose_name: child_contingency_tube_purpose_name
          },
          # sample 2 from well B2 to contingency tube 2 in B1
          {
            name: 'SPR:NT2P:B1',
            foreign_barcode: 'FX00000012',
            barcode_number: 12,
            purpose_uuid: child_contingency_tube_purpose_uuid,
            purpose_name: child_contingency_tube_purpose_name
          },
          # sample 1 from well A3 to contingency tube 3 in C1
          {
            name: 'SPR:NT1O:C1',
            foreign_barcode: 'FX00000013',
            barcode_number: 13,
            purpose_uuid: child_contingency_tube_purpose_uuid,
            purpose_name: child_contingency_tube_purpose_name
          }
        ],
        contingency_tube_rack
      )
    end

    before do
      stub_v2_plate(
        parent_plate,
        stub_search: false,
        custom_includes:
          'wells.aliquots,wells.aliquots.sample,wells.downstream_tubes,' \
            'wells.downstream_tubes.custom_metadatum_collection'
      )
      stub_api_get(parent_uuid, body: parent_v1)
    end

    context 'with both sequencing and contingency files' do
      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_sequencing_tube_rack_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file,
          contingency_file: contingency_file
        }
      end

      # body for stubbing the contingency file upload
      let(:contingency_file_content) do
        content = contingency_file.read
        contingency_file.rewind
        content
      end

      # stub the contingency file upload
      let!(:stub_contingency_file_upload) do
        stub_request(:post, api_url_for(parent_uuid, 'qc_files')).with(
          body: contingency_file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="scrna_core_contingency_tube_rack_scan.csv"'
          }
        ).to_return(
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

      # create the sequencing tubes
      let(:sequencing_tubes) do
        prepare_created_child_tubes(
          [
            # sample 1 in well A1 to seq tube 1 in A1
            {
              name: 'SEQ:NT1O:A1',
              foreign_barcode: 'FX00000001',
              barcode_number: 1,
              purpose_uuid: child_sequencing_tube_purpose_uuid,
              purpose_name: child_sequencing_tube_purpose_name
            },
            # sample 2 in well B1 to seq tube 2 in B1
            {
              name: 'SEQ:NT2P:B1',
              foreign_barcode: 'FX00000002',
              barcode_number: 2,
              purpose_uuid: child_sequencing_tube_purpose_uuid,
              purpose_name: child_sequencing_tube_purpose_name
            }
          ],
          sequencing_tube_rack
        )
      end

      # stub the sequencing file upload
      let!(:stub_sequencing_file_upload) do
        stub_request(:post, api_url_for(parent_uuid, 'qc_files')).with(
          body: sequencing_file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="scrna_core_sequencing_tube_rack_scan.csv"'
          }
        ).to_return(
          status: 201,
          body: json(:qc_file, filename: 'scrna_core_sequencing_tube_rack_scan.csv'),
          headers: {
            'content-type' => 'application/json'
          }
        )
      end

      # stub the transfer creation
      let!(:stub_transfer_creation_request) do
        parent_wells = [parent_well_a1, parent_well_b1, parent_well_a2, parent_well_b2, parent_well_a3]
        target_tubes = sequencing_tubes + contingency_tubes
        transfer_requests =
          parent_wells.map.with_index do |parent_well, index|
            { 'submission_id' => '2', 'source_asset' => parent_well.uuid, 'target_asset' => target_tubes[index].uuid }
          end
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: transfer_requests
            }
          },
          body: '{}'
        )
      end

      let(:contingency_file) do
        fixture_file_upload(
          'spec/fixtures/files/scrna_core/scrna_core_contingency_tube_rack_scan_3_tubes.csv',
          'sequencescape/qc_file'
        )
      end

      before { stub_v2_user(user) }

      it 'creates the child tubes' do
        child_tube_racks = [sequencing_tube_rack, contingency_tube_rack]

        sequencing_tube_parent_well_uuids = [
          parent_plate.well_at_location('A1').uuid,
          parent_plate.well_at_location('B1').uuid
        ]
        contingency_tube_parent_well_uuids = [
          parent_plate.well_at_location('A2').uuid,
          parent_plate.well_at_location('B2').uuid,
          parent_plate.well_at_location('A3').uuid
        ]

        params = {
          sequencing_tubes:,
          sequencing_tube_parent_well_uuids:,
          contingency_tubes:,
          contingency_tube_parent_well_uuids:
        }
        child_tube_rack_attributes = generate_child_tube_rack_attributes(params)

        expect_specific_tube_rack_creation(child_tube_racks, child_tube_rack_attributes)

        # expect_custom_metadatum_collection_posts(
        #   { 'TR00000001' => sequencing_tubes, 'TR00000002' => contingency_tubes }
        # )
        # TODO: check racked tubes? done on SS side so would be mocked anyway

        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_sequencing_file_upload).to have_been_made.once
        expect(stub_contingency_file_upload).to have_been_made.once
        expect(stub_transfer_creation_request).to have_been_made.once
      end

      context 'when a well has been failed' do
        # failing well A1
        let(:parent_well_a1) do
          create(:v2_well, location: 'A1', aliquots: [parent_aliquot_sample1_aliquot1], state: 'failed')
        end

        # one fewer transfer request
        let!(:stub_transfer_creation_request) do
          parent_wells = [parent_well_b1, parent_well_a2, parent_well_b2, parent_well_a3]
          target_tubes = sequencing_tubes + contingency_tubes
          transfer_requests =
            parent_wells.map.with_index do |parent_well, index|
              { 'submission_id' => '2', 'source_asset' => parent_well.uuid, 'target_asset' => target_tubes[index].uuid }
            end
          stub_api_post(
            'transfer_request_collections',
            payload: {
              transfer_request_collection: {
                user: user_uuid,
                transfer_requests: transfer_requests
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

        # create the sequencing tubes
        let(:sequencing_tubes) do
          prepare_created_child_tubes(
            [
              # sample 2 in well B1 to seq tube 1 in A1
              {
                name: 'SEQ:NT2P:A1',
                foreign_barcode: 'FX00000001',
                barcode_number: 1,
                purpose_uuid: child_sequencing_tube_purpose_uuid,
                purpose_name: child_sequencing_tube_purpose_name
              },
              # sample 1 in well A2 to seq tube 2 in B1
              {
                name: 'SEQ:NT1O:B1',
                foreign_barcode: 'FX00000002',
                barcode_number: 2,
                purpose_uuid: child_sequencing_tube_purpose_uuid,
                purpose_name: child_sequencing_tube_purpose_name
              }
            ],
            sequencing_tube_rack
          )
        end

        # create the contingency tubes
        let(:contingency_tubes) do
          prepare_created_child_tubes(
            [
              # sample 2 from well B2 to contingency tube 1 in A1
              {
                name: 'SPR:NT2P:A1',
                foreign_barcode: 'FX00000011',
                barcode_number: 11,
                purpose_uuid: child_contingency_tube_purpose_uuid,
                purpose_name: child_contingency_tube_purpose_name
              },
              # sample 1 from well A3 to contingency tube 2 in B1
              {
                name: 'SPR:NT1O:B1',
                foreign_barcode: 'FX00000012',
                barcode_number: 12,
                purpose_uuid: child_contingency_tube_purpose_uuid,
                purpose_name: child_contingency_tube_purpose_name
              }
            ],
            contingency_tube_rack
          )
        end

        it 'does not create a tube for the failed well' do
          child_tube_racks = [sequencing_tube_rack, contingency_tube_rack]

          sequencing_tube_parent_well_uuids = [
            parent_plate.well_at_location('B1').uuid,
            parent_plate.well_at_location('A2').uuid
          ]
          contingency_tube_parent_well_uuids = [
            parent_plate.well_at_location('B2').uuid,
            parent_plate.well_at_location('A3').uuid
          ]

          params = {
            sequencing_tubes:,
            sequencing_tube_parent_well_uuids:,
            contingency_tubes:,
            contingency_tube_parent_well_uuids:
          }
          child_tube_rack_attributes = generate_child_tube_rack_attributes(params)

          expect_specific_tube_rack_creation(child_tube_racks, child_tube_rack_attributes)

          expect(subject.valid?).to be_truthy
          expect(subject.save).to be_truthy
          expect(stub_sequencing_file_upload).to have_been_made.once
          expect(stub_contingency_file_upload).to have_been_made.once
          expect(stub_transfer_creation_request).to have_been_made.once
        end
      end
    end

    # This test is to check that the correct tube rack and tubes are created when only a sequencing file is provided.
    # NB. The parent plant must have ONLY unique samples in it. No duplicates.
    context 'with just a sequencing file and unique samples' do
      let(:parent_plate) do
        create(
          :v2_plate,
          uuid: parent_uuid,
          wells: [parent_well_a1, parent_well_b1],
          barcode_number: 6,
          ancestors: ancestor_tubes
        )
      end

      let(:form_attributes) do
        {
          user_uuid: user_uuid,
          purpose_uuid: child_sequencing_tube_rack_purpose_uuid,
          parent_uuid: parent_uuid,
          sequencing_file: sequencing_file
        }
      end

      # body for stubbing the sequencing file upload
      let(:sequencing_file_content) do
        content = sequencing_file.read
        sequencing_file.rewind
        content
      end

      # stub the sequencing file upload
      let!(:stub_sequencing_file_upload) do
        stub_request(:post, api_url_for(parent_uuid, 'qc_files')).with(
          body: sequencing_file_content,
          headers: {
            'Content-Type' => 'sequencescape/qc_file',
            'Content-Disposition' => 'form-data; filename="scrna_core_sequencing_tube_rack_scan.csv"'
          }
        ).to_return(
          status: 201,
          body: json(:qc_file, filename: 'scrna_core_sequencing_tube_rack_scan.csv'),
          headers: {
            'content-type' => 'application/json'
          }
        )
      end

      # create the sequencing tubes
      let(:sequencing_tubes) do
        prepare_created_child_tubes(
          [
            # sample 1 from well A1 to sequencing tube 1 in A1
            {
              name: 'SEQ:NT1O:A1',
              foreign_barcode: 'FX00000001',
              barcode_number: 1,
              purpose_uuid: child_sequencing_tube_purpose_uuid,
              purpose_name: child_sequencing_tube_purpose_name
            },
            # sample 2 from well B1 to sequencing tube 2 in B1
            {
              name: 'SEQ:NT2P:B1',
              foreign_barcode: 'FX00000002',
              barcode_number: 2,
              purpose_uuid: child_sequencing_tube_purpose_uuid,
              purpose_name: child_sequencing_tube_purpose_name
            }
          ],
          sequencing_tube_rack
        )
      end

      # stub the transfer creation
      let!(:stub_transfer_creation_request) do
        parent_wells = [parent_well_a1, parent_well_b1]
        transfer_requests =
          parent_wells.map.with_index do |parent_well, index|
            {
              'submission_id' => '2',
              'source_asset' => parent_well.uuid,
              'target_asset' => sequencing_tubes[index].uuid
            }
          end
        stub_api_post(
          'transfer_request_collections',
          payload: {
            transfer_request_collection: {
              user: user_uuid,
              transfer_requests: transfer_requests
            }
          },
          body: '{}'
        )
      end

      before { stub_v2_user(user) }

      it 'creates the child tubes' do
        child_tube_racks = [sequencing_tube_rack]

        sequencing_tube_parent_well_uuids = [
          parent_plate.well_at_location('A1').uuid,
          parent_plate.well_at_location('B1').uuid
        ]

        params = {
          sequencing_tubes: sequencing_tubes,
          sequencing_tube_parent_well_uuids: sequencing_tube_parent_well_uuids,
          contingency_tubes: nil,
          contingency_tube_parent_well_uuids: nil
        }
        child_tube_rack_attributes = generate_child_tube_rack_attributes(params)

        expect_specific_tube_rack_creation(child_tube_racks, child_tube_rack_attributes)

        expect(subject.valid?).to be_truthy
        expect(subject.save).to be_truthy
        expect(stub_sequencing_file_upload).to have_been_made.once
        expect(stub_transfer_creation_request).to have_been_made.once
      end
    end

    # This test is to check it is not valid to have duplicate samples in the parent plate whilst only providing a
    # sequencing file.
    # context 'with just a sequencing file and duplicate samples' do
    #   # TODO: add validation in labware creator and test for duplicate samples
    # end
  end
end
