# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# 2 parent tubes are blended into a single child tube
RSpec.describe LabwareCreators::BlendedTube do
  let(:blend_study) { create :v2_study, name: 'Blend Study' }
  let(:blend_project) { create :v2_project, name: 'Blend Project' }

  let(:sample1) { create(:v2_sample) }
  let(:sample2) { create(:v2_sample) }

  let(:ancestor_plate_purpose_name) { 'Ancestor Plate Purpose' }

  let(:tag_group1) { create(:v2_tag_group, name: 'blendedtg1') }
  let(:tag_group2) { create(:v2_tag_group, name: 'blendedtg2') }

  let(:tag1s) { (1..2).map { |i| create(:v2_tag, map_id: i, tag_group: tag_group1) } }
  let(:tag2s) { (5..6).map { |i| create(:v2_tag, map_id: i, tag_group: tag_group2) } }

  let(:ancestor_aliquot1) { create(:v2_aliquot, sample: sample1, tag: tag1s[0], tag2: tag2s[0]) }
  let(:ancestor_aliquot2) { create(:v2_aliquot, sample: sample2, tag: tag1s[1], tag2: tag2s[1]) }

  let(:ancestor_wells) do
    [
      create(:v2_well, study: blend_study, project: blend_project, aliquots: [ancestor_aliquot1], location: 'A1'),
      create(:v2_well, study: blend_study, project: blend_project, aliquots: [ancestor_aliquot2], location: 'B1')
    ]
  end

  let(:ancestor_plate) do
    create(:v2_plate, purpose_name: ancestor_plate_purpose_name, barcode_number: '1', size: 96, wells: ancestor_wells)
  end

  let(:parent1_tube_uuid) { 'parent-tube1-uuid' }
  let(:parent2_tube_uuid) { 'parent-tube2-uuid' }

  let(:parent1_tube_purpose_uuid) { 'parent-tube-purpose1-uuid' }
  let(:parent2_tube_purpose_uuid) { 'parent-tube-purpose2-uuid' }

  let(:parent1_tube_purpose_name) { 'Parent Tube Purpose 1' }
  let(:parent2_tube_purpose_name) { 'Parent Tube Purpose 2' }

  let(:parent1_receptacle_uuid) { 'parent-receptacle1-uuid' }
  let(:parent2_receptacle_uuid) { 'parent-receptacle2-uuid' }

  let(:parent1_aliquot1) { create(:v2_aliquot, sample: sample1, tag: tag1s[0], tag2: tag2s[0]) }
  let(:parent1_aliquot2) { create(:v2_aliquot, sample: sample2, tag: tag1s[1], tag2: tag2s[1]) }

  # this duplicate of sample 1 should replace one from parent 1 in the destination
  let(:parent2_aliquot1) { create(:v2_aliquot, sample: sample1, tag: tag1s[0], tag2: tag2s[0]) }

  let(:parent1_receptacle) do
    create(
      :v2_receptacle,
      uuid: parent1_receptacle_uuid,
      aliquots: [parent1_aliquot1, parent1_aliquot2],
      qc_results: []
    )
  end
  let(:parent2_receptacle) do
    create(:v2_receptacle, uuid: parent2_receptacle_uuid, aliquots: [parent2_aliquot1], qc_results: [])
  end

  let(:parent1_tube) do
    create :v2_tube,
           uuid: parent1_tube_uuid,
           purpose_name: parent1_tube_purpose_name,
           purpose_uuid: parent1_tube_purpose_uuid,
           receptacle: parent1_receptacle,
           ancestors: [ancestor_plate],
           barcode_number: '2'
  end
  let(:parent2_tube) do
    create :v2_tube,
           uuid: parent2_tube_uuid,
           purpose_name: parent2_tube_purpose_name,
           purpose_uuid: parent2_tube_purpose_uuid,
           receptacle: parent2_receptacle,
           ancestors: [ancestor_plate],
           barcode_number: '3'
  end

  let(:child_tube_purpose_uuid) { 'child-purpose' }
  let(:child_tube_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:list_sample_attributes) { %w[sample_id tag1 tag2] }

  let(:child_tube_uuid) { 'child-tube-uuid' }

  let(:child_tube) do
    create :v2_tube,
           uuid: child_tube_uuid,
           purpose_name: child_tube_purpose_name,
           barcode_number: '4',
           name: 'blended-tube'
  end

  let(:form_attributes) do
    {
      parent_uuid: parent1_tube_uuid,
      purpose_uuid: child_tube_purpose_uuid,
      transfers: [{ source_tube: parent1_tube_uuid }, { source_tube: parent2_tube_uuid }]
    }
  end

  let(:transfer_requests_attributes) do
    [
      {
        source_asset: parent1_tube_uuid,
        target_asset: child_tube_uuid,
        merge_equivalent_aliquots: true,
        list_of_aliquot_attributes_to_consider_a_duplicate: list_sample_attributes,
        keep_this_aliquot_when_deduplicating: false
      },
      {
        source_asset: parent2_tube_uuid,
        target_asset: child_tube_uuid,
        merge_equivalent_aliquots: true,
        list_of_aliquot_attributes_to_consider_a_duplicate: list_sample_attributes,
        keep_this_aliquot_when_deduplicating: true
      }
    ]
  end

  before do
    stub_v2_tube(parent1_tube, stub_search: false)
    stub_v2_tube(parent2_tube, stub_search: false)

    create :blended_tube_purpose_config,
           name: child_tube_purpose_name,
           uuid: child_tube_purpose_uuid,
           ancestor_plate_purpose: ancestor_plate_purpose_name,
           acceptable_parent_tube_purposes: [parent1_tube_purpose_name, parent2_tube_purpose_name],
           single_ancestor_parent_tube_purpose: parent1_tube_purpose_name,
           preferred_purpose_name_when_deduplicating: parent2_tube_purpose_name,
           list_of_aliquot_attributes_to_consider_a_duplicate: list_sample_attributes
  end

  it_behaves_like 'it only allows creation from tubes'

  has_a_working_api

  context 'when validating and transfers is not present' do
    subject { described_class.new(api, purpose_uuid: child_tube_purpose_uuid) }

    it 'is not valid' do
      expect(subject).not_to be_valid
    end

    it 'has an error message' do
      subject.valid?
      expect(subject.errors[:transfers]).to include("can't be blank")
    end
  end

  describe '#create_labware!' do
    subject { described_class.new(api, form_attributes.merge(user_uuid:)) }

    before { allow(subject).to receive_messages(create_child_tube: child_tube) }

    it 'creates a child tube and performs transfers' do
      allow(Sequencescape::Api::V2::TransferRequestCollection).to receive(:create!)

      # Call the private method using `send`
      subject.send(:create_labware!)

      expect(Sequencescape::Api::V2::TransferRequestCollection).to have_received(:create!).with(
        transfer_requests_attributes:,
        user_uuid:
      )
    end
  end

  describe '#request_hash' do
    subject { described_class.new(api, form_attributes.merge(user_uuid:)) }

    before do
      # Stub the @child_tube instance variable
      allow(subject).to receive(:create_child_tube).and_return(child_tube)
      subject.instance_variable_set(:@child_tube, child_tube)
    end

    it 'returns the correct request hash when the parent tube purpose does not match the keep purpose' do
      parent_tube = parent1_tube

      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(uuid: parent_tube.uuid).and_return(parent_tube)

      result = subject.send(:request_hash, { source_tube: parent_tube.uuid })

      expect(result).to eq(
        source_asset: parent_tube.uuid,
        target_asset: child_tube_uuid,
        merge_equivalent_aliquots: true,
        list_of_aliquot_attributes_to_consider_a_duplicate: list_sample_attributes,
        keep_this_aliquot_when_deduplicating: false
      )
    end

    it 'returns the correct request hash when the parent tube purpose matches the keep purpose' do
      parent_tube = parent2_tube

      allow(Sequencescape::Api::V2::Tube).to receive(:find_by).with(uuid: parent_tube.uuid).and_return(parent_tube)

      result = subject.send(:request_hash, { source_tube: parent_tube.uuid })

      expect(result).to eq(
        source_asset: parent_tube.uuid,
        target_asset: child_tube_uuid,
        merge_equivalent_aliquots: true,
        list_of_aliquot_attributes_to_consider_a_duplicate: list_sample_attributes,
        keep_this_aliquot_when_deduplicating: true
      )
    end
  end

  describe '#new' do
    subject { described_class.new(api, form_attributes) }

    let(:form_attributes) do
      {
        purpose_uuid: child_tube_purpose_uuid,
        parent_uuid: parent1_tube_uuid,
        transfers: [{ source_tube: parent1_tube_uuid }, { source_tube: parent2_tube_uuid }]
      }
    end

    it 'can be created' do
      expect(subject).to be_a described_class
    end

    it 'renders the "blended_tube" page' do
      expect(subject.page).to eq('blended_tube')
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_tube_purpose_uuid)
    end
  end

  describe '#create' do
    subject { described_class.new(api, form_attributes.merge(user_uuid:)) }

    let(:child_tube) do
      create :v2_tube,
             uuid: child_tube_uuid,
             purpose_name: child_tube_purpose_name,
             barcode_number: '4',
             name: 'blended-tube'
    end

    let(:specific_tubes_attributes) do
      [
        {
          uuid: child_tube_purpose_uuid,
          parent_uuids: [parent1_tube_uuid, parent2_tube_uuid],
          child_tubes: [child_tube],
          tube_attributes: [{ name: [parent1_tube.human_barcode, parent2_tube.human_barcode].join(':') }]
        }
      ]
    end

    describe '#save!' do
      before { allow(subject).to receive(:parents).and_return([parent1_tube, parent2_tube]) }

      it 'creates a tube' do
        expect_specific_tube_creation
        expect_transfer_request_collection_creation

        subject.save!
      end
    end
  end

  describe '#acceptable_parent_tube_purposes' do
    it 'returns the acceptable parent tube purposes from the purpose config' do
      blended_tube = described_class.new(api, purpose_uuid: child_tube_purpose_uuid)
      expect(blended_tube.acceptable_parent_tube_purposes).to eq([parent1_tube_purpose_name, parent2_tube_purpose_name])
    end
  end

  describe '#single_ancestor_parent_tube_purpose' do
    it 'returns the single ancestor parent tube purpose from the purpose config' do
      blended_tube = described_class.new(api, purpose_uuid: child_tube_purpose_uuid)
      expect(blended_tube.single_ancestor_parent_tube_purpose).to eq(parent1_tube_purpose_name)
    end
  end

  describe '#redirection_target' do
    it 'returns the child tube as the redirection target' do
      blended_tube = described_class.new(api, purpose_uuid: child_tube_purpose_uuid)
      blended_tube.instance_variable_set(:@child_tube, child_tube)
      expect(blended_tube.redirection_target).to eq(child_tube)
    end
  end

  describe '#parent_uuids_from_transfers' do
    it 'extracts unique parent UUIDs from transfers' do
      blended_tube = described_class.new(api, form_attributes.merge(user_uuid:))
      expect(blended_tube.send(:parent_uuids_from_transfers)).to eq([parent1_tube_uuid, parent2_tube_uuid])
    end
  end

  describe '#tube_attributes' do
    it 'generates tube attributes based on parent barcodes' do
      blended_tube = described_class.new(api, form_attributes.merge(user_uuid:))
      allow(blended_tube).to receive(:parents).and_return([parent1_tube, parent2_tube])
      expect(blended_tube.send(:tube_attributes)).to eq(
        [{ name: "#{parent1_tube.human_barcode}:#{parent2_tube.human_barcode}" }]
      )
    end
  end

  describe '#perform_transfers' do
    it 'calls the API to perform transfers' do
      blended_tube = described_class.new(api, form_attributes.merge(user_uuid:))
      allow(blended_tube).to receive(:transfer_request_attributes).and_return(transfer_requests_attributes)

      allow(Sequencescape::Api::V2::TransferRequestCollection).to receive(:create!)

      blended_tube.send(:perform_transfers)

      expect(Sequencescape::Api::V2::TransferRequestCollection).to have_received(:create!).with(
        transfer_requests_attributes:,
        user_uuid:
      )
    end
  end
end
