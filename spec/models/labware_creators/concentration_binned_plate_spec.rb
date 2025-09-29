# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::ConcentrationBinnedPlate do
  subject { described_class.new(form_attributes) }

  it_behaves_like 'it only allows creation from plates'
  it_behaves_like 'it has no custom page'

  let(:parent_uuid) { 'example-plate-uuid' }
  let(:plate_size) { 96 }

  let(:well_a1) do
    create(
      :well,
      position: {
        'name' => 'A1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.5),
      requests_as_source: [requests[0]],
      outer_request: nil
    )
  end

  let(:well_b1) do
    create(
      :well,
      position: {
        'name' => 'B1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 56.0),
      requests_as_source: [requests[1]],
      outer_request: nil
    )
  end

  let(:well_c1) do
    create(
      :well,
      position: {
        'name' => 'C1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 3.5),
      requests_as_source: [requests[2]],
      outer_request: nil
    )
  end

  let(:well_d1) do
    create(
      :well,
      position: {
        'name' => 'D1'
      },
      qc_results: create_list(:qc_result_concentration, 1, value: 1.8),
      requests_as_source: [requests[3]],
      outer_request: nil
    )
  end

  let(:parent_plate) do
    create :plate,
           uuid: parent_uuid,
           barcode_number: '2',
           size: plate_size,
           wells: [well_a1, well_b1, well_c1, well_d1],
           outer_requests: requests
  end

  let(:child_plate) do
    create :plate, uuid: 'child-uuid', barcode_number: '3', size: plate_size, outer_requests: requests
  end

  let(:library_type_name) { 'Test Library Type' }

  let(:requests) do
    Array.new(4) do |i|
      create :library_request, state: 'pending', uuid: "request-#{i}", library_type: library_type_name
    end
  end

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  before do
    create(
      :concentration_binning_purpose_config,
      uuid: child_purpose_uuid,
      name: child_purpose_name,
      library_type_name: library_type_name
    )
    stub_plate(child_plate, stub_search: false)
    stub_plate(
      parent_plate,
      stub_search: false,
      custom_includes:
        'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
    )
  end

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

  context 'on new' do
    it 'can be created' do
      expect(subject).to be_a described_class
    end

    context 'when wells are missing a concentration value' do
      let(:well_e1) { create(:well, position: { 'name' => 'E1' }, qc_results: []) }

      let(:parent_plate) do
        create :plate,
               uuid: parent_uuid,
               barcode_number: '2',
               size: plate_size,
               wells: [well_a1, well_b1, well_c1, well_d1, well_e1],
               outer_requests: requests
      end

      it 'fails validation' do
        expect(subject).not_to be_valid
      end
    end
  end

  context '96 well plate' do
    let(:transfer_requests_attributes) do
      [
        {
          volume: subject.dilutions_calculator.source_volume.to_s,
          source_asset: well_a1.uuid,
          target_asset: '3-well-A1',
          outer_request: requests[0].uuid
        },
        {
          volume: subject.dilutions_calculator.source_volume.to_s,
          source_asset: well_b1.uuid,
          target_asset: '3-well-A3',
          outer_request: requests[1].uuid
        },
        {
          volume: subject.dilutions_calculator.source_volume.to_s,
          source_asset: well_c1.uuid,
          target_asset: '3-well-A2',
          outer_request: requests[2].uuid
        },
        {
          volume: subject.dilutions_calculator.source_volume.to_s,
          source_asset: well_d1.uuid,
          target_asset: '3-well-B1',
          outer_request: requests[3].uuid
        }
      ]
    end

    let(:dest_well_qc_attributes) do
      [
        { 'well_name' => 'A1', 'conc' => '0.42857142857142855' },
        { 'well_name' => 'B1', 'conc' => '0.5142857142857142' },
        { 'well_name' => 'A2', 'conc' => '1.0' },
        { 'well_name' => 'A3', 'conc' => '16.0' }
      ].each.map do |attribs|
        {
          'uuid' => 'child-uuid',
          'well_location' => attribs['well_name'],
          'key' => 'concentration',
          'value' => attribs['conc'],
          'units' => 'ng/ul',
          'cv' => 0,
          'assay_type' => 'ConcentrationBinningCalculator',
          'assay_version' => 'v1.0'
        }
      end
    end

    it_behaves_like 'a QC assaying plate creator'
  end
end
