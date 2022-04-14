# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::Robot, robots: true do
  include RobotHelpers
  has_a_working_api

  let(:user_uuid) { SecureRandom.uuid }
  let(:source_plate_barcode) { source_plate.human_barcode }
  let(:source_plate_barcode_alt) { 'DN1S' }
  let(:source_purpose_name) { 'Limber Cherrypicked' }
  let(:source_plate_state) { 'passed' }
  let(:target_plate_state) { 'pending' }
  let(:source_plate) do
    create :v2_plate, barcode_number: 1, purpose_name: source_purpose_name, state: source_plate_state
  end
  let(:target_barcode) { target_plate.human_barcode }
  let(:target_tube_barcode) { target_tube.human_barcode }
  let(:target_purpose_name) { 'target_plate_purpose' }
  let(:target_tube_purpose_name) { 'target_tube_purpose' }
  let(:target_plate) do
    create :v2_plate,
           purpose_name: target_purpose_name,
           barcode_number: 2,
           parents: target_plate_parents,
           state: target_plate_state
  end
  let(:target_tube_state) { 'pending' }
  let(:target_tube) do
    create :v2_tube,
           purpose_name: target_tube_purpose_name,
           barcode_number: 3,
           state: target_tube_state,
           parents: target_tube_parents
  end
  let(:target_plate_parents) { [source_plate] }
  let(:target_tube_parents) { [source_plate] }
  let(:custom_metadatum_collection) { create :custom_metadatum_collection, metadata: metadata }
  let(:metadata) { { 'other_key' => 'value' } }

  let(:robot) { Robots::Robot.new(robot_spec.merge(api: api, user_uuid: user_uuid)) }

  shared_examples 'a robot' do
    context 'with an unknown plate' do
      before { bed_labware_lookup_with_barcode('dodgy_barcode', []) }
      let(:scanned_layout) { { 'bed1_barcode' => ['dodgy_barcode'] } }

      it { is_expected.not_to be_valid }
    end

    context 'with a plate on an unknown bed' do
      let(:scanned_layout) { { 'bed99_barcode' => [source_plate_barcode] } }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#verify' do
    subject { robot.verify(bed_labwares: scanned_layout) }

    context 'a simple robot' do
      let(:source_purpose) { 'Limber Cherrypicked' }
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 2'
            },
            'bed2_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 1',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_plate)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_barcode] } }

        context 'and related plates' do
          let(:target_plate_parents) { [source_plate] }
          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }
            it { is_expected.not_to be_valid }
          end

          context 'but source is of the wrong purpose' do
            let(:source_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end

          context 'but target is of the wrong purpose' do
            let(:target_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_plate_parents) { [create(:v2_plate)] }
          it { is_expected.not_to be_valid }
        end

        context 'and an unchecked additional parent' do
          let(:target_plate_parents) { [source_plate, create(:v2_plate)] }
          it { is_expected.to be_valid }
        end

        context 'and no parents' do
          let(:target_plate_parents) { [] }
          it { is_expected.not_to be_valid }
        end

        context 'and a parent in the database of a different purpose and an empty parent bed' do
          let(:scanned_layout) { { 'bed1_barcode' => [], 'bed2_barcode' => [target_barcode] } }

          let(:target_plate_parents) { [create(:v2_plate)] }
          it { is_expected.not_to be_valid }
        end

        context 'and multiple source purposes' do
          let(:source_purpose) { ['Limber Cherrypicked', 'Other'] }
          let(:target_plate_parents) { [source_plate] }
          it { is_expected.to be_valid }

          context 'but of the wrong purpose' do
            let(:source_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'with multiple scans' do
        let(:scanned_layout) do
          { 'bed1_barcode' => [source_plate_barcode, 'Other barcode'], 'bed2_barcode' => [target_barcode] }
        end

        context 'and related plates' do
          before { bed_labware_lookup_with_barcode([source_plate_barcode, 'Other barcode'], [source_plate]) }
          let(:target_plate_parents) { [source_plate] }
          it { is_expected.to_not be_valid }
        end
      end
    end

    context 'a robot with beds with multiple parents' do
      let(:source_plate_2) do
        create :v2_plate, barcode_number: 3, purpose_name: source_purpose_name, state: source_plate_state
      end
      let(:source_plate_2_barcode) { source_plate_2.human_barcode }
      let(:target_plate_parents) { [source_plate, source_plate_2] }

      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 2'
            },
            'bed3_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 3'
            },
            'bed2_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 1',
              'parents' => %w[bed1_barcode bed3_barcode],
              'target_state' => 'passed'
            },
            'bed4_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 4'
            },
            'bed6_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 6'
            },
            'bed5_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 5',
              'parents' => %w[bed4_barcode bed6_barcode],
              'target_state' => 'passed'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(source_plate_2)
        bed_labware_lookup(target_plate)
      end

      it_behaves_like 'a robot'

      context 'with only one parent scanned' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_barcode] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed3_barcode' => [source_plate_2_barcode],
            'bed2_barcode' => [target_barcode]
          }
        end

        context 'and related plates' do
          let(:target_plate_parents) { [source_plate, source_plate_2] }
          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }
            it { is_expected.not_to be_valid }
          end

          context 'but of the wrong purpose' do
            let(:source_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_plate_parents) { [create(:v2_plate)] }
          it { is_expected.not_to be_valid }
        end
      end

      context 'with multiple scans' do
        let(:scanned_layout) do
          { 'bed1_barcode' => [source_plate_barcode, 'Other barcode'], 'bed2_barcode' => [target_barcode] }
        end

        context 'and related plates' do
          before { bed_labware_lookup_with_barcode([source_plate_barcode, 'Other barcode'], [source_plate]) }
          let(:target_plate_parents) { [source_plate] }
          it { is_expected.to_not be_valid }
        end
      end
    end

    context 'a robot with tubes as the target' do
      let(:source_purpose) { 'Limber Cherrypicked' }
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => 'target_tube_purpose',
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_tube)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_tube_barcode] } }

        context 'and related plates' do
          let(:target_tube_parents) { [source_plate] }
          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }
            it { is_expected.not_to be_valid }
          end

          context 'but of the wrong purpose' do
            let(:source_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_tube_parents) { [create(:v2_plate)] }
          it { is_expected.not_to be_valid }
        end

        context 'an multiple source purposes' do
          let(:source_purpose) { ['Limber Cherrypicked', 'Other'] }
          let(:target_tube_parents) { [source_plate] }
          it { is_expected.to be_valid }

          context 'but of the wrong purpose' do
            let(:source_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'with multiple scans' do
        let(:scanned_layout) do
          { 'bed1_barcode' => [source_plate_barcode, 'Other barcode'], 'bed2_barcode' => [target_tube_barcode] }
        end

        context 'and related plates' do
          before { bed_labware_lookup_with_barcode([source_plate_barcode, 'Other barcode'], [source_plate]) }
          let(:target_plate_parents) { [source_plate] }
          it { is_expected.to_not be_valid }
        end
      end
    end

    context 'a robot using a shared phiX parent tube' do
      let(:phix_tube_purpose_name) { 'phix_tube_purpose' }
      let(:phix_tube_state) { 'passed' }
      let(:phix_tube) do
        create :v2_tube, purpose_name: phix_tube_purpose_name, barcode_number: 4, state: phix_tube_state
      end
      let(:phix_tube_barcode) { phix_tube.human_barcode }

      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => 'target_tube_purpose',
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parents' => %w[bed1_barcode bed3_barcode],
              'target_state' => 'passed'
            },
            'bed3_barcode' => {
              'purpose' => 'phix_tube_purpose',
              'states' => ['passed'],
              'label' => 'Bed 3',
              'shared_parent' => 'true'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_tube)
        bed_labware_lookup(phix_tube)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed2_barcode' => [target_tube_barcode],
            'bed3_barcode' => [phix_tube_barcode]
          }
        end

        context 'and related labwares' do
          let(:target_tube_parents) { [source_plate, phix_tube] }
          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }
            it { is_expected.not_to be_valid }
          end

          context 'but of the wrong purpose' do
            let(:source_purpose_name) { 'Invalid plate purpose' }
            it { is_expected.not_to be_valid }
          end
        end

        context 'and unrelated labwares' do
          let(:target_tube_parents) { [create(:v2_plate)] }
          it { is_expected.not_to be_valid }
        end

        context 'and multiple transfers' do
          let(:robot_spec) do
            {
              'name' => 'robot_name',
              'beds' => {
                'bed1_barcode' => {
                  'purpose' => 'Limber Cherrypicked',
                  'states' => ['passed'],
                  'label' => 'Bed 1'
                },
                'bed2_barcode' => {
                  'purpose' => 'target_tube_purpose',
                  'states' => ['pending'],
                  'label' => 'Bed 2',
                  'parents' => %w[bed1_barcode bed5_barcode],
                  'target_state' => 'passed'
                },
                'bed3_barcode' => {
                  'purpose' => 'Limber Cherrypicked',
                  'states' => ['passed'],
                  'label' => 'Bed 3'
                },
                'bed4_barcode' => {
                  'purpose' => 'target_tube_purpose',
                  'states' => ['pending'],
                  'label' => 'Bed 4',
                  'parents' => %w[bed3_barcode bed5_barcode],
                  'target_state' => 'passed'
                },
                'bed5_barcode' => {
                  'purpose' => 'phix_tube_purpose',
                  'states' => ['passed'],
                  'label' => 'Bed 5',
                  'shared_parent' => 'true'
                }
              }
            }
          end

          let(:target_tube_parents) { [source_plate, phix_tube] }

          let(:source_plate_2) do
            create :v2_plate, barcode_number: 5, purpose_name: source_purpose_name, state: source_plate_state
          end
          let(:source_plate_2_barcode) { source_plate_2.human_barcode }

          let(:target_tube_2_parents) { [source_plate_2, phix_tube] }
          let(:target_tube_2) do
            create :v2_tube,
                   purpose_name: target_tube_purpose_name,
                   barcode_number: 6,
                   state: target_tube_state,
                   parents: target_tube_2_parents
          end
          let(:target_tube_2_barcode) { target_tube_2.human_barcode }

          before do
            bed_labware_lookup(source_plate)
            bed_labware_lookup(target_tube)
            bed_labware_lookup(source_plate_2)
            bed_labware_lookup(target_tube_2)
            bed_labware_lookup(phix_tube)
          end

          context 'with a valid layout' do
            let(:scanned_layout) do
              {
                'bed1_barcode' => [source_plate_barcode],
                'bed2_barcode' => [target_tube_barcode],
                'bed3_barcode' => [source_plate_2_barcode],
                'bed4_barcode' => [target_tube_2_barcode],
                'bed5_barcode' => [phix_tube_barcode]
              }
            end

            context 'and related labwares' do
              it { is_expected.to be_valid }
            end
          end

          context 'with an invalid layout' do
            let(:scanned_layout) do
              {
                'bed1_barcode' => [source_plate_barcode],
                'bed2_barcode' => [target_tube_barcode],
                'bed3_barcode' => [source_plate_2_barcode],
                'bed4_barcode' => [],
                'bed5_barcode' => [phix_tube_barcode]
              }
            end

            it { is_expected.not_to be_valid }
          end

          context 'with an invalid layout' do
            let(:scanned_layout) do
              {
                'bed1_barcode' => [source_plate_barcode],
                'bed2_barcode' => [target_tube_barcode],
                'bed3_barcode' => [],
                'bed4_barcode' => [],
                'bed5_barcode' => [phix_tube_barcode]
              }
            end

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context 'a robot with grandchildren' do
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            },
            'bed3_barcode' => {
              'purpose' => 'target2_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 3',
              'parent' => 'bed2_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      let(:grandchild_purpose_name) { 'target2_plate_purpose' }
      let(:grandchild_purpose_uuid) { SecureRandom.uuid }
      let(:grandchild_barcode) { grandchild_plate.human_barcode }
      let(:grandchild_plate) do
        create :v2_plate,
               purpose_name: grandchild_purpose_name,
               purpose_uuid: grandchild_purpose_uuid,
               parents: [target_plate],
               barcode_number: 3
      end

      before(:each) do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_plate)
        bed_labware_lookup(grandchild_plate)
      end

      context 'and the correct layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed2_barcode' => [target_barcode],
            'bed3_barcode' => [grandchild_barcode]
          }
        end
        it { is_expected.to be_valid }
      end
    end

    describe 'verify robot' do
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'verify_robot' => true,
          'beds' => {
            'bed1_barcode' => {
              'purpose' => 'Limber Cherrypicked',
              'states' => ['passed'],
              'label' => 'Bed 7'
            }
          }
        }
      end

      before { bed_labware_lookup(source_plate) }

      context 'without metadata' do
        let(:source_plate) do
          create :v2_plate, barcode_number: '123', purpose_name: 'Limber Cherrypicked', state: 'passed'
        end

        it 'is invalid' do
          expect(robot.verify(bed_labwares: { 'bed1_barcode' => [source_plate.human_barcode] })).not_to be_valid
        end
      end

      context 'without plate' do
        it 'is invalid' do
          bed_labware_lookup_with_barcode('dodgy_barcode', [])
          expect(robot.verify(bed_labwares: { 'bed1_barcode' => ['dodgy_barcode'] })).not_to be_falsey
        end
      end

      context 'with metadata' do
        let(:source_plate) do
          create :v2_plate,
                 barcode_number: '123',
                 purpose_name: 'Limber Cherrypicked',
                 state: 'passed',
                 custom_metadatum_collection: custom_metadatum_collection
        end

        it "is invalid if the barcode isn't recorded" do
          expect(
            robot.verify(
              bed_labwares: {
                'bed1_barcode' => [source_plate.human_barcode]
              },
              robot_barcode: 'robot_barcode'
            )
          ).not_to be_valid
        end

        context 'if barcodes differ' do
          let(:metadata) { { 'other_key' => 'value', 'created_with_robot' => 'other_robot' } }
          it 'is invalid' do
            expect(
              robot.verify(
                bed_labwares: {
                  'bed1_barcode' => [source_plate.human_barcode]
                },
                robot_barcode: 'robot_barcode'
              )
            ).not_to be_valid
          end
        end

        context 'if barcodes match' do
          let(:metadata) { { 'other_key' => 'value', 'created_with_robot' => 'robot_barcode' } }
          it 'is valid' do
            expect(
              robot.verify(
                bed_labwares: {
                  'bed1_barcode' => [source_plate.human_barcode]
                },
                robot_barcode: 'robot_barcode'
              )
            ).to be_valid
          end
        end
      end
    end
  end

  describe 'require robot' do
    let(:robot_spec) do
      {
        'name' => 'robot_name',
        'verify_robot' => false,
        'require_robot' => true,
        'beds' => {
          'bed1_barcode' => {
            'purpose' => 'Limber Cherrypicked',
            'states' => ['passed'],
            'label' => 'Bed 7'
          }
        }
      }
    end

    before { bed_labware_lookup(source_plate) }

    it 'is invalid if the robot barcode is not scanned - nil' do
      expect(robot.verify(robot_barcode: nil)).not_to be_valid
    end

    it 'is invalid if the robot barcode is not scanned - empty string' do
      expect(robot.verify(robot_barcode: '')).not_to be_valid
    end

    it 'is valid if the robot barcode is scanned' do
      expect(robot.verify(robot_barcode: 'robot_barcode')).to be_valid
    end
  end

  describe '#perform_transfer' do
    let(:robot_spec) do
      {
        'name' => 'bravo LB End Prep',
        'layout' => 'bed',
        'verify_robot' => true,
        'beds' => {
          '580000014851' => {
            'purpose' => 'LB End Prep',
            'states' => ['started'],
            'label' => 'Bed 14',
            'target_state' => 'passed'
          }
        }
      }
    end
    let(:target_plate_state) { 'started' }

    let(:state_change_request) do
      stub_api_post(
        'state_changes',
        payload: {
          state_change: {
            target_state: 'passed',
            reason: 'Robot bravo LB End Prep started',
            customer_accepts_responsibility: false,
            target: plate.uuid,
            user: user_uuid,
            contents: nil
          }
        },
        body: json(:state_change, target_state: 'passed')
      )
    end

    let(:plate) do
      create :v2_plate,
             barcode_number: '123',
             purpose_uuid: 'lb_end_prep_uuid',
             purpose_name: 'LB End Prep',
             state: target_plate_state
    end

    before do
      create :purpose_config, uuid: 'lb_end_prep_uuid', state_changer_class: 'StateChangers::DefaultStateChanger'
      state_change_request
      bed_labware_lookup(plate)
    end

    it 'performs transfer from started to passed' do
      robot.perform_transfer('580000014851' => [plate.human_barcode])
      expect(state_change_request).to have_been_requested
    end

    context 'if the bed is unexpectedly invalid' do
      let(:target_plate_state) { 'passed' }

      it 'raises a bed error in the event of last-minute errors' do
        expect { robot.perform_transfer('580000014851' => [plate.human_barcode]) }.to raise_error(Robots::Bed::BedError)
      end
    end
  end
end
