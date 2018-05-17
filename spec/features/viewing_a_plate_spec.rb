# frozen_string_literal: true

require 'rails_helper'

feature 'Viewing a plate', js: true do
  has_a_working_api

  let(:user)           { json :user }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:example_plate)  { json :stock_plate, uuid: plate_uuid, barcode_number: 1 }
  let(:example_passed_plate)  { json :stock_plate, uuid: plate_uuid, state: 'passed' }
  let(:example_started_plate) { json :stock_plate, uuid: plate_uuid, state: 'started' }
  let(:wells_collection) { json(:well_collection) }
  let(:default_tube_printer) { 'tube printer 1' }

  # Setup stubs
  background do
    # Set-up the plate config
    Settings.purposes['stock-plate-purpose-uuid'] = build :purpose_config
    Settings.purposes['child-purpose-0'] = build :purpose_config, name: 'Child Purpose 0', parents: ['Limber Cherrypicked']
    Settings.printers[:tube] = default_tube_printer

    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # We lookup the plate
    stub_asset_search(plate_barcode, example_plate)
    # We get the actual plate
    stub_api_get(plate_uuid, body: example_plate)
    stub_api_get(plate_uuid, 'wells', body: wells_collection)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.state-badge')).to have_content('Pending')
    find_link('Download Worksheet CSV', href: "/limber_plates/#{plate_uuid}.csv")
    find_link('Download Concentration CSV', href: '/limber_plates/DN1/exports/concentrations.csv')
  end

  scenario 'if a plate is passed creation of a child is allowed' do
    stub_asset_search(plate_barcode, example_passed_plate)
    stub_api_get(plate_uuid, body: example_passed_plate)
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.state-badge')).to have_content('Passed')
    expect(page).to have_button('Add an empty Child Purpose 0 plate')
  end

  scenario 'if a plate is started creation of a child is not allowed' do
    stub_asset_search(plate_barcode, example_started_plate)
    stub_api_get(plate_uuid, body: example_started_plate)
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find('#plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.state-badge')).to have_content('Started')
    expect(page).not_to have_button('Add an empty Limber Example Purpose plate')
  end

  feature 'with a suboptimal well' do
    let(:wells_collection) { json(:well_collection, aliquot_factory: :suboptimal_aliquot) }
    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('.asset-warnings')).to have_content('Wells contain suboptimal aliquots')
    end
    scenario 'the well is flagged as suboptimal' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(page).to have_css('#aliquot_A1.suboptimal')
    end
  end

  feature 'without a suboptimal well' do
    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('#plate-show-page')).not_to have_content('Wells contain suboptimal aliquots')
    end
    scenario 'the well is flagged as suboptimal' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('#plate-show-page')).not_to have_css('#aliquot_A1.suboptimal')
    end
  end

  feature 'with passed pools' do
    let(:example_plate) { json :stock_plate, uuid: plate_uuid, pool_complete: true, pool_sizes: [5] }
    let(:wells_collection) { json(:well_collection, aliquot_factory: :suboptimal_aliquot) }

    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('.asset-warnings')).to have_content(
        'Libraries on this plate have already been completed. ' \
        'Any further work conducted from this plate may run into issues at the end of the pipeline.'
      )
    end
  end

  feature 'with transfers to tubes' do
    let(:example_plate) { json :plate, uuid: plate_uuid, transfers_to_tubes_count: 1, purpose_uuid: 'child-purpose-0' }
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

    before do
      stub_api_get(plate_uuid, 'transfers_to_tubes', body: json(:transfer_collection))
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

        job = instance_double('Print_job', execute: true)

        expect(PrintJob).to receive(:new).and_return(job).twice

        click_on('Print Label')
      end
    end
  end
end
