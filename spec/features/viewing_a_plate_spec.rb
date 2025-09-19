# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Viewing a plate', :js do
  let(:user) { create :user }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.machine }
  let(:plate_uuid) { SecureRandom.uuid }
  let(:state) { 'pending' }
  let(:purpose_uuid) { 'stock-plate-purpose-uuid' }
  let(:example_plate) do
    create :v2_stock_plate,
           uuid: plate_uuid,
           barcode_number: 1,
           state: state,
           wells: wells_collection,
           purpose_uuid: purpose_uuid
  end
  let(:wells_collection) { %w[A1 B1].map { |loc| create(:v2_well, state: state, position: { 'name' => loc }) } }
  let(:printer_list) { create_list(:v2_tube_barcode_printer, 2) + create_list(:v2_plate_barcode_printer, 2) }
  let(:default_tube_printer) { printer_list.first.name }
  let(:purpose_config) { create :purpose_config, uuid: purpose_uuid }

  # Setup stubs
  background do
    # Set-up the plate config
    purpose_config
    create :purpose_config, name: 'Child Purpose 0', uuid: 'child-purpose-0'
    create :pipeline, relationships: { 'Limber Cherrypicked' => 'Child Purpose 0' }
    Settings.printers[:tube] = default_tube_printer

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We get the actual plate
    stub_v2_plate(example_plate)
    stub_v2_plate(
      example_plate,
      stub_search: false,
      custom_includes: 'wells.aliquots.request.poly_metadata'
    )
    stub_v2_barcode_printers(printer_list)
  end

  scenario 'of a recognised type' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    expect(find_by_id('plate-show-page')).to have_content('Limber Cherrypicked')
    expect(find('.state-badge')).to have_content('Pending')
    find_link('Download Concentration CSV', href: '/plates/DN1S/exports/concentrations.csv')
  end

  context 'with a custom csv' do
    let(:purpose_config) { create :purpose_config, csv_template: 'show_extended', uuid: purpose_uuid }

    scenario 'of a recognised type' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('plate-show-page')).to have_content('Limber Cherrypicked')
      expect(find('.state-badge')).to have_content('Pending')
      find_link('Download Worksheet CSV', href: "/plates/#{plate_uuid}.csv")
      find_link('Download Concentration CSV', href: '/plates/DN1S/exports/concentrations.csv')
    end
  end

  context 'a passed plate' do
    let(:state) { 'passed' }

    scenario 'creation of a child is allowed' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('plate-show-page')).to have_content('Limber Cherrypicked')
      expect(find('.state-badge')).to have_content('Passed')
      expect(page).to have_button('Add an empty Child Purpose 0 plate')
    end
  end

  context 'a started plate' do
    let(:state) { 'started' }

    scenario 'if a plate is started creation of a child is not allowed' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('plate-show-page')).to have_content('Limber Cherrypicked')
      expect(find('.state-badge')).to have_content('Started')
      expect(page).to have_no_button('Add an empty Limber Example Purpose plate')
    end
  end

  feature 'with a suboptimal well' do
    let(:wells_collection) do
      %w[A1 B1].map { |loc| create(:v2_well, state: state, location: loc, aliquot_factory: :v2_suboptimal_aliquot) }
    end

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
      expect(find_by_id('plate-show-page')).to have_no_content('Wells contain suboptimal aliquots')
    end

    scenario 'the well is flagged as suboptimal' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('plate-show-page')).to have_no_css('#aliquot_A1.suboptimal')
    end
  end

  feature 'with passed pools' do
    let(:example_plate) { create :v2_stock_plate, uuid: plate_uuid, library_state: ['passed'], pool_sizes: [5] }

    scenario 'there is a warning' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find('.asset-warnings')).to have_content(
        'Submission Requests of type Limber WGS have already been down the pipeline and were completed.'
      )
    end
  end

  feature 'with a tagged plate' do
    let(:purpose_config) { create :tagged_purpose_config, uuid: purpose_uuid }
    let(:wells_collection) { %w[A1 B1].map { |loc| create(:v2_tagged_well, location: loc) } }

    scenario 'it shows tags' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('aliquot_A1')).to have_content('1')
    end
  end

  feature 'with transfers to tubes' do
    let(:example_plate) do
      create :v2_plate,
             uuid: plate_uuid,
             transfer_targets: {
               'A1' => create_list(:v2_asset_tube, 1)
             },
             purpose_uuid: 'child-purpose-0'
    end
    let(:barcode_printer) { printer_list[1].name }

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

        # So RSpec cautions against this as a code smell, but tbh it feels vastly better than the
        # alternative in integration tests.
        allow_any_instance_of(PrintJob).to receive(:execute).and_return(true)
        stub_v2_plate(example_plate)
        click_on('Print Label')
      end
    end
  end
end
