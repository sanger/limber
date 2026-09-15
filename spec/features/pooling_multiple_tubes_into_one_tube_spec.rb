# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pooling multiple tubes into a tube', :js do
  let(:user_uuid) { SecureRandom.uuid }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }

  # First parent tube
  let(:aliquot_set_1) { create_list :tagged_aliquot, 2, library_state: 'passed' }

  let(:tube_barcode_1) { SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s }
  let(:tube_uuid) { SecureRandom.uuid }
  let(:parent_purpose_name) { 'example-purpose' }
  let(:example_tube) do
    create :tube,
           barcode_number: 1,
           state: 'passed',
           uuid: tube_uuid,
           purpose_name: parent_purpose_name,
           aliquots: aliquot_set_1
  end

  # Second parent tube
  let(:tube_barcode_2) { SBCF::SangerBarcode.new(prefix: 'NT', number: 2).machine_barcode.to_s }
  let(:tube_uuid_2) { SecureRandom.uuid }
  let(:example_tube_2) do
    create :tube,
           barcode_number: 2,
           state: 'passed',
           uuid: tube_uuid_2,
           purpose_name: parent_purpose_name,
           aliquots: aliquot_set_2
  end

  # Child tube
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:template_uuid) { SecureRandom.uuid }

  let(:child_uuid) { 'tube-0' }
  let(:child_tube) { create :tube, purpose_uuid: purpose_uuid, purpose_name: 'Pool tube', uuid: child_uuid }

  # Referred to in api_url_helper
  let(:tube_from_tubes_attributes) do
    [{ child_purpose_uuid: purpose_uuid, parent_uuid: tube_uuid, user_uuid: user_uuid }]
  end

  let(:transfer_requests_attributes) do
    [tube_uuid, tube_uuid_2].map { |source_uuid| { source_asset: source_uuid, target_asset: child_uuid } }
  end

  before do
    # Stubbing API calls
    # Called from the view to populate the list of avaliable parent tubes.
    allow(Sequencescape::Api::V2::Tube).to receive(:find_all).with(
      {
        include_used: false,
        purpose_name: ['example-purpose'],
        state: %w[pending started passed qc_complete failed cancelled]
      },
      { includes: 'purpose', paginate: { page: 1, per_page: 30 } }
    ).and_return([example_tube, example_tube_2])

    # Stub for find_labware_for_pooling: includes receptacle.aliquots then find by uuid
    tube_with_aliquots_query = double('tube_with_aliquots_query')
    allow(Sequencescape::Api::V2::Tube).to receive(:includes).with('receptacle.aliquots').and_return(
      tube_with_aliquots_query
    )
    allow(tube_with_aliquots_query).to receive(:find).with(uuid: tube_uuid).and_return([example_tube])
    allow(tube_with_aliquots_query).to receive(:find).with(uuid: tube_uuid_2).and_return([example_tube_2])

    # Called when looking up the parent tubes that have been scanned in.
    allow(Sequencescape::Api::V2::Tube).to receive(:find_all).with(
      { barcode: [tube_barcode_1, tube_barcode_2] },
      includes: []
    ).and_return([example_tube, example_tube_2])

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
    stub_tube(example_tube)
    stub_tube(example_tube_2)

    # Used in the redirect. This call is probably unnecessary
    stub_tube(child_tube)
    stub_barcode_printers(create_list(:plate_barcode_printer, 3))
  end

  context 'unique tags' do
    let(:aliquot_set_2) { create_list :tagged_aliquot, 2, library_state: 'passed' }

    scenario 'creates multiple tubes' do
      # This isn't strictly speaking correct to test. But there isn't a great way
      # of confirming that the right information got passed to the back end otherwise.
      # (Although you expect it to fail on an incorrect request)
      expect_transfer_request_collection_creation
      expect_tube_from_tube_creation

      fill_in_swipecard_and_barcode(user_swipecard, tube_barcode_1)
      tube_title = find_by_id('tube-title')
      expect(tube_title).to have_text(parent_purpose_name)
      click_on('Add an empty Pool tube tube')
      scan_in('Tube 1', with: tube_barcode_1)
      scan_in('Tube 2', with: tube_barcode_2)
      click_on('Make Pool')
      expect(page).to have_text('New empty labware added to the system')
      expect(page).to have_text('Pool tube')
    end
  end

  context 'clashing tags' do
    let(:aliquot_set_2) { aliquot_set_1 }

    scenario 'detects tag clash' do
      fill_in_swipecard_and_barcode(user_swipecard, tube_barcode_1)
      tube_title = find_by_id('tube-title')
      expect(tube_title).to have_text('example-purpose')
      click_on('Add an empty Pool tube tube')
      scan_in('Tube 1', with: tube_barcode_1)
      scan_in('Tube 2', with: tube_barcode_2)

      expect(page).to have_text(
        'The scanned tube contains tags that would clash with those in other tubes in the pool. ' \
        'Tag clashes found between: NT1O (3980000001795) and NT2P (3980000002808)'
      )

      # removes the error message if another scan is made (NB. currently validation and messages relate to
      # just the currently scanned labware field, the code does NOT re-validate all the scanned fields)
      scan_in('Tube 2', with: '')

      expect(page).to have_no_text(
        'The scanned tube contains tags that would clash with those in other tubes in the pool.'
      )
    end
  end

  context 'incorrect tube state' do
    let(:aliquot_set_2) { create_list :tagged_aliquot, 2, library_state: 'passed' }
    let(:example_tube_2) do
      create :tube,
             barcode_number: 2,
             state: 'pending',
             uuid: tube_uuid_2,
             purpose_name: parent_purpose_name,
             aliquots: aliquot_set_2
    end

    scenario 'creates multiple tubes' do
      fill_in_swipecard_and_barcode(user_swipecard, tube_barcode_1)
      tube_title = find_by_id('tube-title')
      expect(tube_title).to have_text(parent_purpose_name)
      click_on('Add an empty Pool tube tube')
      scan_in('Tube 1', with: tube_barcode_1)
      scan_in('Tube 2', with: tube_barcode_2)

      expect(page).to have_text(
        "Scanned tubes are currently in a 'pending' state when they should be in one of: passed, qc_complete."
      )

      # removes the error message if another scan is made (NB. currently validation and messages relate to
      # just the currently scanned labware field, the code does NOT re-validate all the scanned fields)
      scan_in('Tube 2', with: '')

      expect(page).to have_no_text(
        "Scanned tubes are currently in a 'pending' state when they should be in one of: passed, qc_complete."
      )
    end
  end
end
