# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'Plate transfer', js: true do
  has_a_working_api(times: 7)

  let(:user_uuid) { SecureRandom.uuid }
  let(:user)              { json :user, uuid: user_uuid }
  let(:swipecard)         { 'abcdef' }
  let(:robot_barcode)     { 'robot_barcode'}
  let(:plate_barcode_1)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_barcode_2)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate_uuid)     { SecureRandom.uuid }
  let(:example_plate)  { json :stock_plate, uuid: plate_uuid, purpose_name: 'LB End Prep', purpose_uuid: 'lb_end_prep_uuid' }

   # Setup stubs
  background do
    # Set-up the plate config

    Settings.robots['bravo-lb-post-shear-to-lb-end-prep'] = { name: 'bravo LB Post Shear => LB End Prep', layout: 'bed',
    beds:
      {'580000004838'=> {
                     purpose: "LB Post Shear",
                     states: ['passed'],
                     label: 'Bed 4'},
             '580000014851' => {
                            purpose: 'LB End Prep',
                            states: ["pending"],
                            label: 'Bed 14',
                            parent: '580000004838',
                            target_state: 'passed'} } }
    # # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => swipecard } }, user)
  end

  scenario 'saves the robot barcode' do
    allow_any_instance_of(Robots::Robot).to receive(:verify).and_return({beds: {"580000004838"=>true, "580000014851"=>true}, valid: true, message: ''})
    # allow_any_instance_of(Robots::Robot).to receive(:perform_transfer).and_return(true)

    Settings.purpose_uuids['LB End Prep'] = 'lb_end_prep_uuid'
    Settings.purposes['lb_end_prep_uuid'] = { state_changer_class: 'StateChangers::DefaultStateChanger' }
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode_2 } }, example_plate)
    stub = stub_api_post('state_changes',
             payload: {state_change: {"target_state" => "passed", "reason" => "Robot bravo LB Post Shear => LB End Prep started", "customer_accepts_responsibility" => false, "target" => plate_uuid, "user" => user_uuid }},
             body: json(:state_change))
    stub = stub_api_post('custom_metadatum_collections',
             payload: { custom_metadatum_collection: { user: user_uuid, asset: plate_uuid, metadata: {created_with_robot: 'robot_barcode'} } },
             body: json(:custom_metadatum_collection))

    fill_in_swipecard_and_barcode(swipecard)

    #if we don't do this the next step doesn't work
    expect(page).to have_content("Jane Doe")
    click_button('Robots')
    click_link "bravo LB Post Shear => LB End Prep"
    expect(page).to have_content("bravo LB Post Shear => LB End Prep")
    fill_in "Scan robot", with: robot_barcode
    fill_in "Scan bed", with: '580000004838'
    fill_in "Scan plate", with: plate_barcode_1

    within('#bed_list') do
      expect(page).to have_content("Robot: #{robot_barcode}")
      expect(page).to have_content("Plate: #{plate_barcode_1}")
      expect(page).to have_content("Bed: 580000004838")
    end

    fill_in "Scan bed", with: '580000014851'
    fill_in "Scan plate", with: plate_barcode_2
     within('#bed_list') do
      expect(page).to have_content("Robot: #{robot_barcode}", count: 2)
      expect(page).to have_content("Plate: #{plate_barcode_1}")
      expect(page).to have_content("Bed: 580000004838")
      expect(page).to have_content("Plate: #{plate_barcode_2}")
      expect(page).to have_content("Bed: 580000014851")
    end


    click_link('Validate Layout')
    within '#validation_report' do
      expect(page).to have_content('No problems detected!')
    end
    click_button("Start the bravo LB Post Shear => LB End Prep")
    expect(page).to have_content("Robot bravo LB Post Shear => LB End Prep has been started.")
  end

   def fill_in_swipecard_and_barcode(swipecard)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
    end
  end



end

