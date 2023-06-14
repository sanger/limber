# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate.
# Creates and adds new control samples to the child plate.
# Adds the controls to randomised well locations on the child plate, potentially displacing samples
# that would otherwise have been stamped across.
RSpec.describe LabwareCreators::StampedPlateAddingRandomisedControls do
  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  has_a_working_api

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }
  let(:parent_plate_v2) do
    create :v2_stock_plate, uuid: parent_uuid, barcode_number: '2', size: plate_size, outer_requests: requests
  end
  let(:child_plate_v2) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, outer_requests: requests
  end
  let(:requests) { Array.new(plate_size) { |i| create :library_request, state: 'started', uuid: "request-#{i}" } }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:parent_plate_includes) do
    'wells.requests_as_source,wells.requests_as_source.request_type,' \
      'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'
  end
  let(:control_well_locations) { %w[B5 H3] }

  let(:control_study_name) { 'UAT Study' }
  let(:control_study) { create :v2_study, name: control_study_name }

  let(:control_project_name) { 'UAT Project' }
  let(:control_project) { create :v2_project, name: control_project_name }

  let(:sample_md_cohort) { 'Cohort' }
  let(:sample_md_sample_description) { 'Description' }

  let(:control_pos_sample_name) { 'CONTROL_POS_Description_B5' }
  let(:control_neg_sample_name) { 'CONTROL_NEG_Description_B5' }

  let!(:control_pos_sample_metadata) do
    create :v2_sample_metadata,
           supplier_name: control_pos_sample_name,
           cohort: sample_md_cohort,
           sample_description: sample_md_sample_description
  end

  let!(:control_neg_sample_metadata) do
    create :v2_sample_metadata,
           supplier_name: control_neg_sample_name,
           cohort: sample_md_cohort,
           sample_description: sample_md_sample_description
  end

  let(:control_sample_pos) do
    create :v2_sample,
           name: control_pos_sample_name,
           control: true,
           control_type: 'pcr positive',
           sample_metadata: control_pos_sample_metadata
  end

  let(:control_sample_neg) do
    create :v2_sample,
           name: control_neg_sample_name,
           control: true,
           control_type: 'pcr negative',
           sample_metadata: control_neg_sample_metadata
  end

  let(:child_well_pos) { child_plate_v2.wells.find { |well| well.position['name'] == control_well_locations[0] } }
  let(:child_well_neg) { child_plate_v2.wells.find { |well| well.position['name'] == control_well_locations[1] } }

  let(:control_aliquot_pos) do
    create :v2_aliquot,
           sample: control_sample_pos,
           study: control_study,
           project: control_project,
           receptacle: child_well_pos
  end

  let(:control_aliquot_neg) do
    create :v2_aliquot,
           sample: control_sample_neg,
           study: control_study,
           project: control_project,
           receptacle: child_well_neg
  end

  before do
    create(
      :stamp_with_randomised_controls_purpose_config,
      name: child_purpose_name,
      uuid: child_purpose_uuid,
      control_study_name: control_study_name
    )
    stub_v2_plate(child_plate_v2, stub_search: false, custom_query: [:plate_with_wells, child_plate_v2.uuid])
    stub_v2_plate(parent_plate_v2, stub_search: false, custom_includes: parent_plate_includes)
    stub_v2_study(control_study)
    stub_v2_project(control_project)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  subject { LabwareCreators::StampedPlateAddingRandomisedControls.new(api, form_attributes) }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a LabwareCreators::StampedPlateAddingRandomisedControls
    end
  end

  shared_examples 'a stamped plate adding randomised controls creator' do
    describe '#save!' do
      let!(:plate_creation_request) do
        stub_api_post(
          'plate_creations',
          payload: {
            plate_creation: {
              parent: parent_uuid,
              child_purpose: child_purpose_uuid,
              user: user_uuid
            }
          },
          body: json(:plate_creation)
        )
      end

      let!(:api_v2_post) { stub_api_v2_post('Sample') }

      let!(:api_v2_update_sample_metadata) { stub_api_v2_post('SampleMetadata') }

      let!(:api_v2_save_aliquot) { stub_api_v2_save('Aliquot') }

      let!(:transfer_creation_request) do
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

      it 'makes the expected requests' do
        expect(subject.save!).to eq true
        expect(plate_creation_request).to have_been_made
        expect(transfer_creation_request).to have_been_made
      end
    end
  end

  context '96 well plate' do
    let(:plate_size) { 96 }

    let(:transfer_requests) do
      control_locations = subject.generate_control_well_locations

      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .filter_map do |well_name, index|
          next if control_locations.include?(well_name)
          {
            'source_asset' => "2-well-#{well_name}",
            'target_asset' => "3-well-#{well_name}",
            'outer_request' => "request-#{index}"
          }
        end
    end

    before do
      allow(subject).to receive(:generate_control_well_locations).and_return(control_well_locations)
      allow(subject).to receive(:create_control_sample).and_return(control_sample_pos, control_sample_neg)
    end

    it_behaves_like 'a stamped plate adding randomised controls creator'
  end

  context '384 well plate' do
    let(:plate_size) { 384 }

    let(:transfer_requests) do
      control_locations = subject.generate_control_well_locations

      WellHelpers
        .column_order(plate_size)
        .each_with_index
        .filter_map do |well_name, index|
          next if control_locations.include?(well_name)
          {
            source_asset: "2-well-#{well_name}",
            target_asset: "3-well-#{well_name}",
            outer_request: "request-#{index}"
          }
        end
    end

    before do
      allow(subject).to receive(:generate_control_well_locations).and_return(control_well_locations)
      allow(subject).to receive(:create_control_sample).and_return(control_sample_pos, control_sample_neg)
    end

    it_behaves_like 'a stamped plate adding randomised controls creator'
  end

  context 'when generating control locations' do
    let(:plate_size) { 96 }

    before { parent_plate_v2 }

    context 'when the rule checks pass' do
      before { allow(subject).to receive(:validate_control_rules).and_return(true) }

      it 'returns the expected number of locations' do
        expect(subject.generate_control_well_locations.length).to eq subject.list_of_controls.length
      end
    end

    context 'when a control has a fixed location' do
      before do
        allow(subject).to receive(:validate_control_rules).and_return(true)
        create(
          :stamp_with_randomised_controls_purpose_config,
          name: child_purpose_name,
          uuid: child_purpose_uuid,
          control_study_name: control_study_name,
          controls: [
            { control_type: 'pcr positive', name_prefix: 'CONTROL_POS_', fixed_location: 'G12' },
            { control_type: 'pcr negative', name_prefix: 'CONTROL_NEG_' }
          ]
        )
      end

      it 'the result includes that location' do
        positive_location = subject.generate_control_well_locations.first
        expect(positive_location).to eq 'G12'
      end

      it 'returns the expected number of locations' do
        expect(subject.generate_control_well_locations.length).to eq subject.list_of_controls.length
      end
    end

    context 'when the rule checks fail' do
      before do
        allow(subject).to receive(:validate_control_rules).and_return(false)
        subject.generate_control_well_locations
      end

      it 'returns an error' do
        expected_msg = 'Control well location randomisation failed to pass rules after 5 attempts'
        expect(subject.errors.first.message).to eq expected_msg
      end
    end
  end

  # test the various control location generation rule types
  context 'when validating well location rules' do
    context 'when rule type is not' do
      before do
        create(
          :stamp_with_randomised_controls_purpose_config,
          name: child_purpose_name,
          uuid: child_purpose_uuid,
          control_study_name: control_study_name,
          control_location_rules: [{ type: 'not', value: %w[H1 G1] }]
        )
      end

      context 'when failing the rule' do
        let(:control_well_locations) { %w[H1 G1] }

        it 'returns false' do
          expect(subject.validate_control_rules(control_well_locations)).to eq false
        end
      end

      context 'when passing the rule' do
        let(:control_well_locations) { %w[A1 C2] }

        it 'returns true' do
          expect(subject.validate_control_rules(control_well_locations)).to eq true
        end
      end
    end

    context 'when rule is well_exclusions' do
      before do
        create(
          :stamp_with_randomised_controls_purpose_config,
          name: child_purpose_name,
          uuid: child_purpose_uuid,
          control_study_name: control_study_name,
          control_location_rules: [{ type: 'well_exclusions', value: %w[H10 H11 H12] }]
        )
      end

      context 'when failing the rule' do
        let(:control_well_locations) { %w[A1 H12] }

        it 'returns false' do
          expect(subject.validate_control_rules(control_well_locations)).to eq false
        end
      end

      context 'when passing the rule' do
        let(:control_well_locations) { %w[A1 C2] }

        it 'returns true' do
          expect(subject.validate_control_rules(control_well_locations)).to eq true
        end
      end
    end
  end
end
