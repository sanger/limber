# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pooling multiple tubes into a tube', js: true do
  has_a_working_api

  let(:user_uuid) { SecureRandom.uuid }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }

  let(:aliquot_set_1) { create_list :v2_tagged_aliquot, 2, library_state: 'passed' }

  let(:parent_1) { create :v2_plate, barcode_number: 3 }
  let(:parent_1_v1) { json :plate_with_metadata, barcode_number: 3 }
  let(:parent_2) { create :v2_plate, barcode_number: 4 }
  let(:parent_2_v1) { json :plate_with_metadata, barcode_number: 4 }

  let(:tube_barcode_1) { SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s }
  let(:tube_uuid) { SecureRandom.uuid }
  let(:parent_purpose_name) { 'example-purpose' }
  let(:example_tube_args) do
    [
      :tube,
      {
        barcode_number: 1,
        state: 'passed',
        uuid: tube_uuid,
        purpose_name: parent_purpose_name,
        aliquots: aliquot_set_1
      }
    ]
  end
  let(:stock_plate_purpose_name) { 'Stock Plate Purpose' }
  let(:stock_plate) { create :v2_stock_plate, purpose_name: stock_plate_purpose_name }
  let(:example_v2_tube) do
    create :v2_tube,
           barcode_number: 1,
           state: 'passed',
           uuid: tube_uuid,
           purpose_name: parent_purpose_name,
           aliquots: aliquot_set_1,
           stock_plate: stock_plate,
           parents: [parent_1]
  end
  let(:example_tube) { json(*example_tube_args) }
  let(:example_tube_listed) { associated(*example_tube_args) }

  let(:tube_barcode_2) { SBCF::SangerBarcode.new(prefix: 'NT', number: 2).machine_barcode.to_s }
  let(:tube_uuid_2) { SecureRandom.uuid }
  let(:example_tube2_args) do
    [:tube, { barcode_number: 2, state: 'passed', uuid: tube_uuid_2, aliquots: aliquot_set_2 }]
  end
  let(:example_tube_2) { json(*example_tube2_args) }
  let(:example_v2_tube2) do
    create :v2_tube,
           barcode_number: 2,
           state: 'passed',
           uuid: tube_uuid_2,
           purpose_name: parent_purpose_name,
           aliquots: aliquot_set_2,
           stock_plate: stock_plate,
           parents: [parent_2]
  end
  let(:example_tube_2_listed) { associated(*example_tube2_args) }

  let(:purpose_uuid) { SecureRandom.uuid }
  let(:template_uuid) { SecureRandom.uuid }

  let(:barcodes) { [tube_barcode_1, tube_barcode_2] }

  let(:child_uuid) { 'tube-0' }
  let(:child_tube) { json :tube, purpose_uuid: purpose_uuid, purpose_name: 'Pool tube', uuid: child_uuid }
  let(:child_tube_v2) { create :v2_tube, purpose_uuid: purpose_uuid, purpose_name: 'Pool tube', uuid: child_uuid }

  let(:tube_creation_request_uuid) { SecureRandom.uuid }

  let!(:tube_creation_request) do
    # TODO: In reality we want to link in all four parents.
    stub_api_post(
      'tube_from_tube_creations',
      payload: {
        tube_from_tube_creation: {
          user: user_uuid,
          parent: tube_uuid,
          child_purpose: purpose_uuid
        }
      },
      body: json(:tube_creation, child_uuid: child_uuid)
    )
  end

  # Find out what tubes we've just made!
  let!(:tube_creation_children_request) do
    stub_api_get(
      tube_creation_request_uuid,
      'children',
      body: json(:single_study_multiplexed_library_tube_collection, names: ['DN2+'])
    )
  end

  let!(:order_requests) do
    stub_api_get(template_uuid, body: json(:submission_template, uuid: template_uuid))
    stub_api_post(
      template_uuid,
      'orders',
      payload: {
        order: {
          assets: [child_uuid],
          request_options: {
            read_length: 150
          },
          user: user_uuid
        }
      },
      body: '{"order":{"uuid":"order-uuid"}}'
    )
    stub_api_post(
      'submissions',
      payload: {
        submission: {
          orders: ['order-uuid'],
          user: user_uuid
        }
      },
      body: json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }])
    )
    stub_api_post('sub-uuid', 'submit')
  end

  let(:transfer_requests_attributes) do
    [tube_uuid, tube_uuid_2].map { |source_uuid| { source_asset: source_uuid, target_asset: child_uuid } }
  end

  def expect_transfer_request_collection_creation
    expect_api_v2_posts(
      'TransferRequestCollection',
      [{ transfer_requests_attributes: transfer_requests_attributes, user_uuid: user_uuid }]
    )
  end

  before do
    allow(Sequencescape::Api::V2::Tube).to receive(:find_all)
      .with(
        include_used: false,
        purpose_name: ['example-purpose'],
        includes: 'purpose',
        paginate: {
          size: 30,
          number: 1
        }
      )
      .and_return([example_v2_tube, example_v2_tube2])

    # Parent lookup
    allow(Sequencescape::Api::V2::Tube).to receive(:find_all)
      .with(barcode: [tube_barcode_1, tube_barcode_2], includes: [])
      .and_return([example_v2_tube, example_v2_tube2])

    # Allow parent plates to be found in API v2
    stub_v2_plate(parent_1, stub_search: false)
    stub_v2_plate(parent_2, stub_search: false)
  end

  background do
    create :tube_config, name: parent_purpose_name, uuid: 'example-purpose-uuid'
    create :pooled_tube_from_tubes_purpose_config,
           uuid: purpose_uuid,
           name: 'Pool tube',
           submission: {
             template_uuid: template_uuid,
             options: {
               read_length: 150
             }
           }
    create :pipeline, relationships: { parent_purpose_name => 'Pool tube' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    stub_v2_tube(example_v2_tube)
    stub_v2_tube(example_v2_tube2)

    # Available tubes search
    allow(Sequencescape::Api::V2::Tube).to receive(:find_all)
      .with(
        include_used: false,
        purpose_name: ['example-purpose'],
        includes: 'purpose',
        paginate: {
          size: 30,
          number: 1
        }
      )
      .and_return([example_v2_tube, example_v2_tube2])

    # Parent lookup
    allow(Sequencescape::Api::V2::Tube).to receive(:find_all)
      .with(barcode: [tube_barcode_1, tube_barcode_2], includes: [])
      .and_return([example_v2_tube, example_v2_tube2])

    # Old API still used when loading parent
    stub_api_get(tube_uuid, body: example_tube)

    # Used in the redirect. This is call is probably unnecessary
    stub_api_get(child_uuid, body: child_tube)
    stub_v2_tube(child_tube_v2)
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))

    allow(SearchHelper).to receive(:stock_plate_names).and_return([stock_plate_purpose_name])
    stub_get_labware_metadata(parent_1.barcode.machine, parent_1_v1)
  end

  context 'unique tags' do
    let(:aliquot_set_2) { create_list :v2_tagged_aliquot, 2, library_state: 'passed' }

    scenario 'creates multiple tubes' do
      # This isn't strictly speaking correct to test. But there isn't a great way
      # of confirming that the right information got passed to the back end otherwise.
      # (Although you expect it to fail on an incorrect request)
      # Also see the related note at the end of the scenario.
      expect_transfer_request_collection_creation

      fill_in_swipecard_and_barcode(user_swipecard, tube_barcode_1)
      tube_title = find('#tube-title')
      expect(tube_title).to have_text(parent_purpose_name)
      click_on('Add an empty Pool tube tube')
      scan_in('Tube 1', with: tube_barcode_1)
      scan_in('Tube 2', with: tube_barcode_2)
      click_on('Make Pool')
      expect(page).to have_text('New empty labware added to the system')
      expect(page).to have_text('Pool tube')

      # Ditto in relation to this not being the correct place to test this, but see the note at the top of the scenario.
      expect(tube_creation_request).to have_been_made
    end
  end

  context 'clashing tags' do
    let(:aliquot_set_2) { aliquot_set_1 }

    scenario 'detects tag clash' do
      fill_in_swipecard_and_barcode(user_swipecard, tube_barcode_1)
      tube_title = find('#tube-title')
      expect(tube_title).to have_text('example-purpose')
      click_on('Add an empty Pool tube tube')
      scan_in('Tube 1', with: tube_barcode_1)
      scan_in('Tube 2', with: tube_barcode_2)

      expect(page).to have_text(
        'The scanned tube contains tags that would clash with those in other tubes in the pool. ' \
          'Tag clashes found between: NT1 (3980000001795) and NT2 (3980000002808)'
      )

      # removes the error message if another scan is made (NB. currently validation and messages relate to
      # just the currently scanned labware field, the code does NOT re-validate all the scanned fields)
      scan_in('Tube 2', with: '')

      expect(page).to_not have_text(
        'The scanned tube contains tags that would clash with those in other tubes in the pool.'
      )
    end
  end
end
