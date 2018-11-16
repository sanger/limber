# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Viewing a plate', js: true do
  has_a_working_api

  let(:user)           { json :user }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode)  { example_plate.barcode.machine }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:plate_state) { 'pending' }
  let(:example_plate) { create :v2_stock_plate, uuid: plate_uuid, size: 384, state: plate_state }
  let(:default_tube_printer) { 'tube printer 1' }

  # Setup stubs
  background do
    # Set-up the plate config
    create :minimal_purpose_config, uuid: 'stock-plate-purpose-uuid'
    create :minimal_purpose_config,
           uuid: 'child-purpose-0',
           name: 'Child Purpose 0',
           parents: ['Limber Cherrypicked']
    Settings.printers[:tube] = default_tube_printer

    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # We get the actual plate
    stub_v2_plate(example_plate)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.state-badge')).to have_content('Pending')
  end

  context 'a passed plate' do
    let(:plate_state) { 'passed' }

    scenario 'if a plate is passed creation of a child is allowed' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
      expect(find('.state-badge')).to have_content('Passed')
      expect(page).to have_button('Add an empty Child Purpose 0 plate')
    end
  end

  context 'a started plate' do
    let(:plate_state) { 'started' }

    scenario 'if a plate is started creation of a child is not allowed' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
      expect(find('.state-badge')).to have_content('Started')
      expect(page).not_to have_button('Add an empty Limber Example Purpose plate')
    end
  end

  feature 'with passed pools' do
    let(:example_plate) { create :v2_stock_plate, uuid: plate_uuid, library_state: ['passed'], pool_sizes: [5] }

    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('.asset-warnings')).to have_content(
        'Libraries on this plate have already been completed. ' \
        'Any further work conducted from this plate may run into issues at the end of the pipeline.'
      )
    end
  end

  feature 'plates with 384 wells' do
    let(:example_plate) { create :v2_stock_plate, uuid: plate_uuid, library_state: ['passed'], size: 384, pool_sizes: [5, 12, 48, 48, 9, 35, 35, 5, 12, 48, 48, 9, 35, 35] }
    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('.asset-warnings')).to have_content(
        'Libraries on this plate have already been completed. ' \
        'Any further work conducted from this plate may run into issues at the end of the pipeline.'
      )
    end
  end

  feature 'with transfers to tubes' do
    let(:example_plate) { create :v2_plate, uuid: plate_uuid, transfer_targets: { 'A1' => create_list(:v2_asset_tube, 1) }, purpose_uuid: 'child-purpose-0' }
    let(:barcode_printer) { 'tube printer 0' }
    let(:print_copies) { 2 }

    let(:label_a) do
      { "label": {
        "top_line": 'Child tube 0 prefix',
        "middle_line": 'Example purpose',
        "bottom_line": ' 7-JUN-2017',
        "round_label_top_line": 'NT',
        "round_label_bottom_line": '1',
        "barcode": '3980000001795'
      } }
    end

    let(:label_b) do
      { "label": {
        "top_line": 'Child tube 1 prefix',
        "middle_line": 'Example purpose',
        "bottom_line": ' 7-JUN-2017',
        "round_label_top_line": 'NT',
        "round_label_bottom_line": '2',
        "barcode": '3980000001795'
      } }
    end

    scenario 'we see the tube label form' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(page).to have_content('Print tube labels')
      expect(page).to have_select('Barcode Printer', selected: default_tube_printer)
    end

    scenario 'we can use the tube label form' do
      # expect(job).to receive(:execute).and_return(true)

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      within('.tube-printing') do
        expect(page).to have_content('Print tube labels')
        select(barcode_printer, from: 'Barcode Printer')

        allow_any_instance_of(PrintJob).to receive(:execute).and_return(true)
        stub_v2_plate(example_plate)
        click_on('Print Label')
      end
    end
  end
end
