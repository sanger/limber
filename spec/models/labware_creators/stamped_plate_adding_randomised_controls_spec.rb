# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# Uses a custom transfer template to transfer material into the new plate.
# Creates and adds new control samples to the child plate.
# Adds the controls to randomised well locations on the child plate, potentially displacing samples
# that would otherwise have been stamped across.
RSpec.describe LabwareCreators::StampedPlateAddingRandomisedControls do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }
  let(:parent_plate) do
    create :stock_plate, uuid: parent_uuid, barcode_number: '2', size: plate_size, outer_requests: requests
  end
  let(:child_plate) { create :plate_empty, uuid: 'child-uuid', barcode_number: '3', size: plate_size }
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
  let(:control_study) { create :study, name: control_study_name }

  let(:control_project_name) { 'UAT Project' }
  let(:control_project) { create :project, name: control_project_name }

  let(:sample_md_cohort) { 'Cohort' }
  let(:sample_md_sample_description) { 'Description' }

  let(:control_pos_sample_name) { 'CONTROL_POS_Description_B5' }
  let(:control_neg_sample_name) { 'CONTROL_NEG_Description_B5' }

  let!(:control_pos_sample_metadata) do
    create :sample_metadata,
           supplier_name: control_pos_sample_name,
           cohort: sample_md_cohort,
           sample_description: sample_md_sample_description
  end

  let!(:control_neg_sample_metadata) do
    create :sample_metadata,
           supplier_name: control_neg_sample_name,
           cohort: sample_md_cohort,
           sample_description: sample_md_sample_description
  end

  let(:control_sample_pos) do
    create :sample,
           name: control_pos_sample_name,
           control: true,
           control_type: 'pcr positive',
           sample_metadata: control_pos_sample_metadata
  end

  let(:control_sample_neg) do
    create :sample,
           name: control_neg_sample_name,
           control: true,
           control_type: 'pcr negative',
           sample_metadata: control_neg_sample_metadata
  end

  before do
    create(
      :stamp_with_randomised_controls_purpose_config,
      name: child_purpose_name,
      uuid: child_purpose_uuid,
      control_study_name: control_study_name
    )
    stub_plate(child_plate, stub_search: false, custom_query: [:plate_with_wells, child_plate.uuid])
    stub_plate(parent_plate, stub_search: false, custom_includes: parent_plate_includes)
    stub_study(control_study)
    stub_project(control_project)
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end
  end

  shared_examples 'a stamped plate adding randomised controls creator' do
    describe '#save!' do
      let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

      before do
        stub_patch('Sample')
        stub_patch('SampleMetadata')
        stub_save('Aliquot')
      end

      it 'makes the expected requests' do
        expect_plate_creation
        expect_transfer_request_collection_creation

        expect(subject.save!).to be true
      end
    end
  end

  context '96 well plate' do
    let(:plate_size) { 96 }

    let(:transfer_requests_attributes) do
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

  context '384 well plate' do
    let(:plate_size) { 384 }

    let(:transfer_requests_attributes) do
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

    before { parent_plate }

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
      before { allow(subject).to receive(:validate_control_rules).and_return(false) }

      it 'returns an error' do
        expected_msg = 'Control well location randomisation failed to pass rules after 5 attempts'
        expect { subject.generate_control_well_locations }.to raise_error(StandardError, expected_msg)
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
          expect(subject.validate_control_rules(control_well_locations)).to be false
        end
      end

      context 'when passing the rule' do
        let(:control_well_locations) { %w[A1 C2] }

        it 'returns true' do
          expect(subject.validate_control_rules(control_well_locations)).to be true
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
          expect(subject.validate_control_rules(control_well_locations)).to be false
        end
      end

      context 'when passing the rule' do
        let(:control_well_locations) { %w[A1 C2] }

        it 'returns true' do
          expect(subject.validate_control_rules(control_well_locations)).to be true
        end
      end
    end
  end

  describe '#register_stock_for_plate' do
    let(:logger) { instance_double(Logger) }
    let(:child_uuid) { 'child-uuid' }
    let(:child_plate_v2) { create(:plate) }
    let(:child) { create(:plate, uuid: child_uuid) }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      subject.instance_variable_set(:@child_plate_v2, child_plate_v2)
      subject.instance_variable_set(:@child, child)
    end

    context 'when stock registration succeeds' do
      before { allow(child_plate_v2).to receive(:register_stock_for_plate).and_return(true) }

      it 'logs a success message' do
        expect(logger).to receive(:info).with(/Stock registration successful for plate #{child_uuid}/)
        subject.send(:register_stock_for_plate)
      end
    end

    context 'when stock registration fails' do
      before do
        allow(child_plate_v2).to receive(:register_stock_for_plate).and_return(false)
        allow(child_plate_v2).to receive_message_chain(:errors, :full_messages).and_return(['Something went wrong'])
      end

      it 'logs an error message with the errors' do
        expect(logger).to receive(:error).with(
          /Stock registration failed for plate #{child_uuid}: Something went wrong/
        )
        subject.send(:register_stock_for_plate)
      end
    end

    context 'when an exception occurs' do
      before do
        allow(child_plate_v2).to receive(:register_stock_for_plate).and_raise(StandardError, 'unexpected failure')
      end

      it 'logs an exception error message' do
        expect(logger).to receive(:error).with(/Stock registration error for plate #{child_uuid}: unexpected failure/)
        subject.send(:register_stock_for_plate)
      end
    end
  end

  describe '#generate_control_sample_desc' do
    let(:plate_size) { 96 }
    let(:sample_metadata) { create :sample_metadata, sample_description: test_description }
    let(:sample) { create :sample, sample_metadata: }
    let(:aliquot) { create :aliquot, sample: }

    before do
      allow(parent_plate).to receive_message_chain(
        :wells,
        :first,
        :aliquots,
        :first,
        :sample,
        :sample_metadata,
        :sample_description
      ).and_return(test_description)
      # Setup the parent_wells_with_aliquots method to return a well with our test aliquot
      allow(subject).to receive(:parent_wells_with_aliquots).and_return([instance_double('Well', aliquots: [aliquot])])
    end

    context 'when sample description is present' do
      let(:test_description) { 'Test Description' }

      it 'returns the sample description from the parent well' do
        expect(subject.send(:generate_control_sample_desc)).to eq(test_description)
      end
    end

    context 'when sample description is blank' do
      let(:test_description) { '' }

      before { allow(parent_plate).to receive(:human_barcode).and_return('TEST-BARCODE') }

      it 'returns the parent plate barcode' do
        expect(subject.send(:generate_control_sample_desc)).to eq('TEST-BARCODE')
      end
    end
  end

  describe '#create_control_sample_name' do
    let(:plate_size) { 96 }
    let(:control) { instance_double('Control', name_prefix: 'CONTROL_POS_') }
    let(:well_location) { 'B5' }
    let(:child_barcode) { 'CHILD-12345' }

    before do
      RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
      # subject.@child is created at initialisation, so is expected to be nil at this point - therefore allow it
      allow(subject.instance_variable_get(:@child)).to receive_message_chain(:labware_barcode, :human).and_return(
        child_barcode
      )
    end

    it 'returns a properly formatted control sample name' do
      expected_name = 'CONTROL_POS_CHILD-12345_B5'
      expect(subject.send(:create_control_sample_name, control, well_location)).to eq(expected_name)
    end

    it 'includes the control name prefix, child barcode, and well location' do
      sample_name = subject.send(:create_control_sample_name, control, well_location)
      expect(sample_name).to include(control.name_prefix, child_barcode, well_location)
    end
  end
end
