# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Creating a plate', :js, :tag_plate do
  has_a_working_api
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.machine }
  let(:plate_uuid) { SecureRandom.uuid }
  let(:another_plate_uuid) { SecureRandom.uuid }
  let(:child_purpose_uuid) { 'child-purpose-0' }
  let(:child_purpose_name) { 'Basic' }
  let(:request_type_a) { create :request_type, key: 'rt_a' }
  let(:request_type_b) { create :request_type, key: 'rt_b' }
  let(:request_a) { create :library_request, request_type: request_type_a, uuid: 'request-0' }
  let(:request_b) { create :library_request, request_type: request_type_b, uuid: 'request-2' }
  let(:request_c) { create :library_request, request_type: request_type_a, uuid: 'request-1' }
  let(:request_d) { create :library_request, request_type: request_type_b, uuid: 'request-3' }
  let(:wells) do
    [
      create(:v2_stock_well, uuid: '6-well-A1', location: 'A1', aliquot_count: 1, requests_as_source: [request_a]),
      create(:v2_stock_well, uuid: '6-well-B1', location: 'B1', aliquot_count: 1, requests_as_source: [request_c]),
      create(:v2_stock_well, uuid: '6-well-C1', location: 'C1', aliquot_count: 0, requests_as_source: [])
    ]
  end

  let(:example_plate) do
    create :v2_stock_plate, barcode_number: 6, uuid: plate_uuid, wells: wells, purpose_name: 'Limber Cherrypicked'
  end

  let(:another_plate) do
    create :v2_stock_plate,
           barcode_number: 106,
           uuid: another_plate_uuid,
           wells: wells,
           purpose_name: 'Limber Cherrypicked'
  end

  let(:alternative_plate) do
    create :v2_stock_plate,
           barcode_number: 107,
           uuid: another_plate_uuid,
           wells: wells,
           purpose_name: alternative_purpose_name
  end

  let(:alternative_purpose_name) { 'Alternative identifier plate' }

  let(:child_plate) do
    create :v2_plate, uuid: 'child-uuid', barcode_number: 7, state: 'passed', purpose_name: child_purpose_name
  end

  let(:plate_creations_attributes) do
    [{ child_purpose_uuid: child_purpose_uuid, parent_uuid: plate_uuid, user_uuid: user_uuid }]
  end

  let(:filters) { {} }

  let(:transfer_requests_attributes) do
    WellHelpers.column_order(96)[0, 2].each_with_index.map do |well_name, index|
      { source_asset: "6-well-#{well_name}", target_asset: "7-well-#{well_name}", outer_request: "request-#{index}" }
    end
  end

  # Setup stubs
  background do
    # Set-up the plate config
    create :purpose_config, uuid: example_plate.purpose.uuid
    create(:purpose_config, name: child_purpose_name, uuid: 'child-purpose-0')
    create(:pipeline, relationships: { 'Limber Cherrypicked' => child_purpose_name }, filters: filters)

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We get the actual plate
    2.times { stub_v2_plate(example_plate) }
    stub_v2_plate(child_plate, stub_search: false)
    stub_v2_plate(
      example_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_v2_plate(
      child_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  scenario 'basic plate creation' do
    expect_plate_creation
    expect_transfer_request_collection_creation

    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    plate_title = find_by_id('plate-title')
    expect(plate_title).to have_text('Limber Cherrypicked')
    click_on('Add an empty Basic plate')
    expect(page).to have_content('New empty labware added to the system.')
  end

  context 'when printing a label' do
    let(:label_template_id) { 1 }
    let(:label_templates) { [double('label_template', id: label_template_id)] }
    let(:job) { double('job') }
    let(:ancestors_scope) { double('ancestors_scope') }

    before do
      expect_plate_creation
      expect_transfer_request_collection_creation

      allow(child_plate).to receive(:fetch_stock_plate_ancestors).and_return(stock_plates)
      allow(child_plate).to receive(:stock_plate).and_return(stock_plates.last)
      allow(child_plate).to receive(:ancestors).and_return(ancestors_scope)
      allow(ancestors_scope).to receive(:where).with(purpose_name: alternative_purpose_name).and_return(
        [alternative_plate]
      )

      allow(job).to receive(:save).and_return(true)
      allow(PMB::PrintJob).to receive(:new) do |args|
        @data_printed = args
        job
      end
      allow(PMB::LabelTemplate).to receive(:where).and_return(label_templates)

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find_by_id('plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
    end

    context 'when the plate has one stock plate' do
      let(:stock_plates) { [example_plate] }

      before do
        click_on('Add an empty Basic plate')
        expect(page).to have_content('New empty labware added to the system.')

        click_on('Print Label')
        expect(PMB::PrintJob).to have_received(:new)
      end

      it 'prints the stock plate in the top right of the label' do
        first_label = @data_printed[:labels][:body][0]
        expect(first_label['main_label']['top_right']).to eq(child_plate.stock_plate.barcode.human)
      end
    end

    context 'when the plate has several stock plates' do
      before do
        allow(SearchHelper).to receive(:alternative_workline_reference_name).with(child_plate).and_return(alternatives)

        click_on('Add an empty Basic plate')
        expect(page).to have_content('New empty labware added to the system.')

        click_on('Print Label')
        expect(PMB::PrintJob).to have_received(:new)
      end

      let(:stock_plates) { [another_plate, example_plate] }

      context 'when there is not alternative workline_identifiers' do
        let(:alternatives) { nil }

        it 'prints the last stock plate in the top right of the label' do
          first_label = @data_printed[:labels][:body][0]
          expect(first_label['main_label']['top_right']).to eq(stock_plates.last.barcode.human)
        end
      end

      context 'when there is alternative workline identifier' do
        let(:alternatives) { alternative_purpose_name }

        it 'prints the workline identifier' do
          first_label = @data_printed[:labels][:body][0]
          expect(first_label['main_label']['top_right']).to eq(alternative_plate.barcode.human)
        end
      end
    end
  end

  context 'with multiple requests and no config' do
    let(:wells) do
      [
        create(
          :v2_stock_well,
          uuid: '6-well-A1',
          location: 'A1',
          aliquot_count: 1,
          requests_as_source: [request_a, request_b]
        ),
        create(
          :v2_stock_well,
          uuid: '6-well-B1',
          location: 'B1',
          aliquot_count: 1,
          requests_as_source: [request_c, request_d]
        ),
        create(:v2_stock_well, uuid: '6-well-C1', location: 'C1', aliquot_count: 0, requests_as_source: [])
      ]
    end

    # We'll eventually add in a disambiguation page here
    scenario 'basic plate creation' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find_by_id('plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Basic plate')
      expect(page).to have_content('Cannot create the next piece of labware')
      expect(page).to have_content('Well filter found 2 eligible requests for A1')
    end
  end

  context 'with multiple requests and config with request type filter' do
    let(:filters) { { request_type: ['rt_a'] } }
    let(:wells) do
      [
        create(
          :v2_stock_well,
          uuid: '6-well-A1',
          location: 'A1',
          aliquot_count: 1,
          requests_as_source: [request_a, request_b]
        ),
        create(
          :v2_stock_well,
          uuid: '6-well-B1',
          location: 'B1',
          aliquot_count: 1,
          requests_as_source: [request_c, request_d]
        ),
        create(:v2_stock_well, uuid: '6-well-C1', location: 'C1', aliquot_count: 0, requests_as_source: [])
      ]
    end

    scenario 'basic plate creation' do
      expect_plate_creation
      expect_transfer_request_collection_creation

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find_by_id('plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Basic plate')
      expect(page).to have_content('New empty labware added to the system.')
    end
  end

  context 'with multiple requests and config with request and library type filters' do
    let(:library_type_name) { 'LibTypeA' }
    let(:filters) { { 'request_type' => ['rt_a'], 'library_type' => [library_type_name] } }

    let(:request_a) do
      create :library_request, request_type: request_type_a, uuid: 'request-0', library_type: library_type_name
    end

    let(:request_c) do
      create :library_request, request_type: request_type_a, uuid: 'request-1', library_type: library_type_name
    end

    let(:wells) do
      [
        create(
          :v2_stock_well,
          uuid: '6-well-A1',
          location: 'A1',
          aliquot_count: 1,
          requests_as_source: [request_a, request_b]
        ),
        create(
          :v2_stock_well,
          uuid: '6-well-B1',
          location: 'B1',
          aliquot_count: 1,
          requests_as_source: [request_c, request_d]
        ),
        create(:v2_stock_well, uuid: '6-well-C1', location: 'C1', aliquot_count: 0, requests_as_source: [])
      ]
    end

    scenario 'basic plate creation' do
      expect_plate_creation
      expect_transfer_request_collection_creation

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      plate_title = find_by_id('plate-title')
      expect(plate_title).to have_text('Limber Cherrypicked')
      click_on('Add an empty Basic plate')
      expect(page).to have_content('New empty labware added to the system.')
    end
  end
end
