# frozen_string_literal: true

require 'robot_configuration'

ROBOT_CONFIG = RobotConfiguration::Register.configure do
  # Simple robots and bravo robots both transfer a single 'passed' source plate to a single 'pending'
  # destination plate. They pass the target plate
  # Simple robots can transition to started if their second argument is 'started'

  # Custom robots are configured manually

  bravo_robot do
    from 'LB Cherrypick', bed(7)
    to 'LB Shear', bed(9)
  end

  bravo_robot do
    from 'LB Shear', bed(9)
    to 'LB Post Shear', bed(7)
  end

  bravo_robot 'started' do
    from 'LB Post Shear', bed(4)
    to 'LB End Prep', bed(14)
  end

  custom_robot('bravo-lb-end-prep',
               name: 'bravo LB End Prep',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(7).barcode => { purpose: 'LB End Prep', states: ['started'], label: 'Bed 7', target_state: 'passed' }
               })

  bravo_robot do
    from 'LB End Prep', bed(7)
    to 'LB Lib PCR', bed(6)
  end

  custom_robot('lib-pcr-purification',
               name: 'bravo LB Lib PCR => LB Lib PCR XP',
               layout: 'bed',
               verify_robot: false,
               beds: {
                 bed(1).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 1' },
                 bed(9).barcode  => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 9', parent: bed(1).barcode, target_state: 'passed' },
                 bed(2).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 2' },
                 bed(10).barcode => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 10', parent: bed(2).barcode, target_state: 'passed' },
                 bed(3).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 3' },
                 bed(11).barcode => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 11', parent: bed(3).barcode, target_state: 'passed' },
                 bed(4).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 4' },
                 bed(12).barcode => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 12', parent: bed(4).barcode, target_state: 'passed' }
               })

  custom_robot('nx-8-lib-pcr-xp-to-isch-lib-pool',
               name: 'nx-8 Lib PCR-XP => LB Lib PrePool',
               layout: 'bed',
               beds: {
                 bed(2).barcode => { purpose: 'LB Lib PCR-XP', states: ['qc_complete'], child: bed(4).barcode, label: 'Bed 2' },
                 bed(5).barcode => { purpose: 'LB Lib PCR-XP', states: ['qc_complete'], child: bed(4).barcode, label: 'Bed 5' },
                 bed(3).barcode => { purpose: 'LB Lib PCR-XP', states: ['qc_complete'], child: bed(4).barcode, label: 'Bed 3' },
                 bed(6).barcode => { purpose: 'LB Lib PCR-XP', states: ['qc_complete'], child: bed(4).barcode, label: 'Bed 6' },
                 bed(4).barcode => {
                   purpose: 'LB Lib PrePool',
                   states: %w[pending started],
                   parents: [bed(2).barcode, bed(5).barcode, bed(3).barcode, bed(6).barcode, bed(2).barcode, bed(5).barcode, bed(3).barcode, bed(6).barcode],
                   target_state: 'passed',
                   label: 'Bed 4'
                 }
               },
               destination_bed: bed(4).barcode,
               class: 'Robots::PoolingRobot')

  simple_robot('nx-8') do
    from 'LB Lib PrePool', bed(2)
    to 'LB Hyb', bed(4)
  end

  bravo_robot do
    from 'LB Hyb', bed(4)
    to 'LB Cap Lib', car('1,3')
  end

  bravo_robot do
    from 'LB Cap Lib', bed(4)
    to 'LB Cap Lib PCR', car('4,5')
  end

  simple_robot('nx-96') do
    from 'LB Cap Lib PCR', bed(1)
    to 'LB Cap Lib PCR-XP', bed(9)
  end

  simple_robot('nx-8') do
    from 'LB Cap Lib PCR-XP', bed(4)
    to 'LB Cap Lib pool', bed(2)
  end
end
