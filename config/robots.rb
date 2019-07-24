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

  bravo_robot transition_to: 'started' do
    from 'LB Post Shear', bed(4)
    to 'LB End Prep', bed(14)
  end

  custom_robot('bravo-lb-end-prep',
               name: 'bravo LB End Prep',
               verify_robot: true,
               beds: {
                 bed(7).barcode => {
                  purpose: 'LB End Prep',
                  states: ['started'],
                  label: 'Bed 7',
                  target_state: 'passed' }
               })

  bravo_robot do
    from 'LB End Prep', bed(7)
    to 'LB Lib PCR', bed(6)
  end

  custom_robot('lib-pcr-purification',
               name: 'bravo LB Lib PCR => LB Lib PCR XP',
               verify_robot: false,
               beds: {
                 bed(1).barcode => {
                  purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 1' },
                 bed(9).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: ['pending'],
                  label: 'Bed 9',
                  parent: bed(1).barcode,
                  target_state: 'passed' },
                 bed(2).barcode => {
                  purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 2' },
                 bed(10).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: ['pending'],
                  label: 'Bed 10',
                  parent: bed(2).barcode,
                  target_state: 'passed' },
                 bed(3).barcode => {
                  purpose: 'LB Lib PCR',
                  states: ['passed'],
                  label: 'Bed 3' },
                 bed(11).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: ['pending'],
                  label: 'Bed 11',
                  parent: bed(3).barcode,
                  target_state: 'passed' },
                 bed(4).barcode => {
                  purpose: 'LB Lib PCR',
                  states: ['passed'],
                  label: 'Bed 4' },
                 bed(12).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: ['pending'],
                  label: 'Bed 12',
                  parent: bed(4).barcode,
                  target_state: 'passed' }
               })

  custom_robot('zephyr-lib-pcr-purification',
               name: 'Zephyr LB Lib PCR => LB Lib PCR XP',
               verify_robot: false,
               beds: {
                 bed(2).barcode => {
                  purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 2' },
                 bed(7).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: ['pending'],
                  label: 'Bed 7',
                  parent: bed(2).barcode,
                  target_state: 'passed' }
               })

  custom_robot('nx-8-lib-pcr-xp-to-isch-lib-pool',
               name: 'nx-8 Lib PCR-XP => LB Lib PrePool',
               beds: {
                 bed(2).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: %w[passed qc_complete], child: bed(4).barcode,
                  label: 'Bed 2' },
                 bed(5).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: %w[passed qc_complete], child: bed(4).barcode,
                  label: 'Bed 5' },
                 bed(3).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: %w[passed qc_complete], child: bed(4).barcode,
                  label: 'Bed 3' },
                 bed(6).barcode => {
                  purpose: 'LB Lib PCR-XP',
                  states: %w[passed qc_complete], child: bed(4).barcode,
                  label: 'Bed 6' },
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
    to 'LB Cap Lib Pool', bed(2)
  end

  simple_robot('nx-8') do
    from 'LB Cap Lib PCR-XP', bed(4)
    to 'LB Cap Lib Pool', bed(2)
  end

  bravo_robot do
    from 'PF Cherrypicked', bed(7)
    to 'PF Shear', bed(9)
  end

  bravo_robot do
    from 'PF Shear', bed(9)
    to 'PF Post Shear', bed(7)
  end

  bravo_robot(transition_to: 'started') do
    from 'PF Post Shear', bed(4)
    to 'PF Post Shear XP', car('2,3')
  end

  custom_robot(
    'nx-96-pf-post-shear-to-pf-post-shear-xp',
    name: 'nx-96 PF Post-Shear => PF Post-Shear XP',
    beds: {
      bed(1).barcode => {
        purpose: 'PF Post Shear',
        states: ['passed'],
        label: 'Bed 1' },
      bed(9).barcode => {
        purpose: 'PF Post Shear XP',
        states: ['pending'],
        label: 'Bed 9',
        parent: bed(1).barcode,
        target_state: 'started' },
      bed(2).barcode => {
        purpose: 'PF Post Shear',    states: ['passed'],  label: 'Bed 2' },
      bed(10).barcode => {
        purpose: 'PF Post Shear XP',
        states: ['pending'],
        label: 'Bed 10',
        parent: bed(2).barcode,
        target_state: 'started' },
      bed(3).barcode => {
        purpose: 'PF Post Shear',
        states: ['passed'],
        label: 'Bed 3' },
      bed(11).barcode => {
        purpose: 'PF Post Shear XP',
        states: ['pending'],
        label: 'Bed 11',
        parent: bed(3).barcode,
        target_state: 'started' },
      bed(4).barcode => {
        purpose: 'PF Post Shear',
        states: ['passed'],
        label: 'Bed 4' },
      bed(12).barcode => {
        purpose: 'PF Post Shear XP',
        states: ['pending'],
        label: 'Bed 12',
        parent: bed(4).barcode,
        target_state: 'started' }
    }
  )

  bravo_robot transition_to: 'started' do
    from 'scRNA Stock', bed(4)
    to 'scRNA cDNA-XP', car('2,3')
  end

  bravo_robot transition_to: 'started' do
    from 'GnT Stock', bed(4)
    to 'scRNA cDNA-XP', car('2,3')
  end

  custom_robot(
    'star-384-scrna-384-stock-to-scrna-384-cdna-xp',
    name: 'STAR-384 scRNA Stock => scRNA-384 cDNA-XP',
    beds: {
      bed(12).barcode => {
        purpose: 'scRNA-384 Stock',
        states: ['passed'],
        label: 'Bed 12' },
      bed(17).barcode => {
        purpose: 'scRNA-384 cDNA-XP',
        states: ['pending'],
        label: 'Bed 17',
        parent: bed(12).barcode,
        target_state: 'passed' },
      bed(13).barcode => {
        purpose: 'scRNA-384 Stock',
        states: ['passed'],
        label: 'Bed 13' },
      bed(18).barcode => {
        purpose: 'scRNA-384 cDNA-XP',
        states: ['pending'],
        label: 'Bed 18',
        parent: bed(13).barcode,
        target_state: 'passed' },
      bed(14).barcode => {
        purpose: 'scRNA-384 Stock',
        states: ['passed'],
        label: 'Bed 14' },
      bed(19).barcode => {
        purpose: 'scRNA-384 cDNA-XP',
        states: ['pending'],
        label: 'Bed 19',
        parent: bed(14).barcode,
        target_state: 'passed' },
      bed(15).barcode => {
        purpose: 'scRNA-384 Stock',
        states: ['passed'],
        label: 'Bed 15' },
      bed(20).barcode => {
        purpose: 'scRNA-384 cDNA-XP',
        states: ['pending'],
        label: 'Bed 20',
        parent: bed(15).barcode,
        target_state: 'passed' }
    }
  )

  bravo_robot transition_to: 'started' do
    from 'scRNA cDNA-XP', bed(4)
    to 'scRNA End Prep', car('1,4')
  end

  bravo_robot transition_to: 'started' do
    from 'scRNA-384 cDNA-XP', bed(4)
    to 'scRNA-384 End Prep', car('1,4')
  end

  custom_robot('bravo-scdna-end-prep',
               name: 'bravo scDNA End Prep',
               verify_robot: true,
               beds: {
                 bed(5).barcode => {
                  purpose: 'scRNA End Prep',
                  states: ['started'],
                  label: 'Bed 5',
                  target_state: 'passed' }
               })

  custom_robot('bravo-scdna-384-end-prep',
               name: 'bravo scDNA-384 End Prep',
               verify_robot: true,
               beds: {
                 bed(5).barcode => {
                  purpose: 'scRNA-384 End Prep',
                  states: ['started'],
                  label: 'Bed 5',
                  target_state: 'passed' }
               })

  bravo_robot do
    from 'scRNA End Prep', car('1,4')
    to 'scRNA Lib PCR', bed(6)
  end

  bravo_robot do
    from 'scRNA-384 End Prep', car('1,4')
    to 'scRNA-384 Lib PCR', bed(6)
  end

  custom_robot(
    'bravo-pf-post-shear-to-pf-end-prep',
    name: 'Bravo PF Post-Shear => PF End Prep',
    beds: {
      bed(4).barcode => {
        purpose: 'PF Post Shear',
        states: ['passed'],
        label: 'Bed 4' },
      car('1,4').barcode => {
        purpose: 'PF End Prep',
        states: ['pending'],
        label: 'Carousel 1,4',
        parent: bed(4).barcode,
        target_state: 'started' }
    }
  )

  custom_robot(
    'bravo-pf-end-prep',
    name: 'Bravo PF End Preparation',
    beds: {
      bed(5).barcode => {
        purpose: 'PF End Prep',
        states: ['started'],
        label: 'Bed 5',
        target_state: 'passed' }
    }
  )

  custom_robot(
    'bravo-pf-post-shear-xp-prep',
    name: 'Bravo PF Post Shear XP Preparation',
    beds: {
      bed(5).barcode => {
        purpose: 'PF Post Shear XP',
        states: ['started'],
        label: 'Bed 5',
        target_state: 'passed' }
    }
  )

  custom_robot('hamilton-star-pf-post-shear-to-pf-post-shear-xp-384',
               name: 'Hamilton STAR-384 PF-Post Shear => PF-384 Post Shear XP',
               beds: {
                 bed(12).barcode => {
                  purpose: 'PF Post Shear',
                  states: %w[passed qc_complete], child: bed(7).barcode,
                  label: 'Bed 12' },
                 bed(13).barcode => {
                  purpose: 'PF Post Shear',
                  states: %w[passed qc_complete], child: bed(7).barcode,
                  label: 'Bed 13' },
                 bed(14).barcode => {
                  purpose: 'PF Post Shear',
                  states: %w[passed qc_complete], child: bed(7).barcode,
                  label: 'Bed 14' },
                 bed(15).barcode => {
                  purpose: 'PF Post Shear',
                  states: %w[passed qc_complete], child: bed(7).barcode,
                  label: 'Bed 15' },
                 bed(7).barcode => {
                   purpose: 'PF-384 Post Shear XP',
                   states: %w[pending],
                   parents: [bed(12).barcode, bed(13).barcode, bed(14).barcode, bed(15).barcode],
                   target_state: 'passed',
                   label: 'Bed 7'
                 }
               },
               destination_bed: bed(7).barcode,
               class: 'Robots::QuadrantRobot')

  custom_robot(
    'bravo-pf-post-shear-xp-to-pf-lib-xp',
    name: 'Bravo PF Post Shear XP to PF Lib XP',
    beds: {
      car('1,3').barcode => {
        purpose: 'PF Post Shear XP',
        states: ['passed'],
        label: 'Carousel 1,3' },
      bed(6).barcode => {
        purpose: 'PF Lib',
        states: ['pending'],
        label: 'Bed 6',
        target_state: 'passed',
        parent: car('1,3').barcode },
      car('4,3').barcode => {
        purpose: 'PF Lib XP',
        states: ['pending'],
        label: 'Carousel 4,3',
        target_state: 'passed',
        parent: bed(6).barcode }
    }
  )

  custom_robot(
    'bravo-pf-end-prep-to-pf-lib-xp-2',
    name: 'Bravo PF End Prep to PF Lib XP2',
    beds: {
      bed(5).barcode => {
        purpose: 'PF End Prep',
        states: ['passed'],
        label: 'Bed 5' },
      bed(6).barcode => {
        purpose: 'PF Lib',
        states: ['pending'],
        label: 'Bed 6',
        target_state: 'passed',
        parent: bed(5).barcode },
      car('4,3').barcode => {
        purpose: 'PF Lib XP2',
        states: ['pending'],
        label: 'Carousel 4,3',
        target_state: 'passed',
        parent: bed(6).barcode }
    }
  )

  bravo_robot transition_to: 'started' do
    from 'PF-384 Post Shear XP', bed(4)
    to 'PF-384 End Prep', car('1,4')
  end

  custom_robot('bravo-pf-384-end-prep',
               name: 'Bravo PF-384 End Prep End Preparation',
               verify_robot: true,
               beds: {
                 bed(5).barcode => {
                  purpose: 'PF-384 End Prep',
                  states: ['started'],
                  label: 'Bed 5',
                  target_state: 'passed' }
               })

  custom_robot(
    'bravo-pf-384-end-prep-to-pf-384-lib-xp-2',
    name: 'Bravo PF-384 End Prep to PF-384 Lib XP2',
    beds: {
      bed(5).barcode => {
        purpose: 'PF-384 End Prep',
        states: ['passed'],
        label: 'Bed 5' },
      bed(6).barcode => {
        purpose: 'PF-384 Lib',
        states: ['pending'],
        label: 'Bed 6',
        target_state: 'passed',
        parent: bed(5).barcode },
      car('4,3').barcode => {
        purpose: 'PF-384 Lib XP2',
        states: ['pending'],
        label: 'Carousel 4,3',
        target_state: 'passed',
        parent: bed(6).barcode }
    }
  )

  custom_robot(
    'bravo-pf-384-lib-xp2-to-pl-lib-xp2',
    name: 'Bravo PF-384 Lib XP2 => PF-Lib Q-XP2',
    beds: {
      bed(5).barcode => {
        purpose: 'PF-384 Lib XP2',
        label: 'Bed 5',
        states: ['passed']
      },
      bed(1).barcode => {
        purpose: 'PF Lib Q-XP2',
        label: 'Bed 1',
        states: ['pending'],
        target_state: 'passed'
      },
      bed(4).barcode => {
        purpose: 'PF Lib Q-XP2',
        label: 'Bed 4',
        states: ['pending'],
        target_state: 'passed'
      },
      bed(3).barcode => {
        purpose: 'PF Lib Q-XP2',
        label: 'Bed 3',
        states: ['pending'],
        target_state: 'passed'
      },
      bed(6).barcode => {
        purpose: 'PF Lib Q-XP2',
        label: 'Bed 6',
        states: ['pending'],
        target_state: 'passed'
      }
    },
    class: 'Robots::SplittingRobot',
    relationships: [{
        'type' => 'quad_stamp_out',
        'options' => {
          'parent' => bed(5).barcode,
          'children' => [bed(1).barcode, bed(4).barcode, bed(3).barcode, bed(6).barcode]
        }
      }]
  )

  custom_robot(
    'bravo-mrna-capture-rnaag',
    name: 'Bravo mRNA capture RNAAG',
    beds: {
      bed(7).barcode => {
        purpose: 'LBR Cherrypick',
        states: ['passed'],
        label: 'Bed 7' },
      bed(6).barcode => {
        purpose: 'LBR mRNA Cap',
        states: ['pending'],
        label: 'Bed 6',
        target_state: 'started',
        parent: bed(7).barcode },
      car('2,3').barcode => {
        purpose: 'LBR Globin',
        states: ['pending'],
        label: 'Carousel 2,3',
        parent: bed(6).barcode }
    }
  )

  custom_robot(
    'bravo-mrna-capture-rnaa',
    name: 'Bravo mRNA capture RNAA',
    beds: {
      bed(7).barcode => {
        purpose: 'LBR Cherrypick',
        states: ['passed'],
        label: 'Bed 7' },
      bed(6).barcode => {
        purpose: 'LBR mRNA Cap',
        states: ['pending'],
        label: 'Bed 6',
        target_state: 'started',
        parent: bed(7).barcode },
      car('2,3').barcode => {
        purpose: 'LBR Frag',
        states: ['pending'],
        label: 'Carousel 2,3',
        parent: bed(6).barcode },
      car('3,4').barcode => {
        purpose: 'LB cDNA',
        states: ['pending'],
        label: 'Carousel 3,4',
        parent: car('2,3').barcode },
      car('4,3').barcode => {
        purpose: 'LB cDNA XP',
        states: ['pending'],
        label: 'Carousel 4,3',
        parent: car('3,4').barcode }
    }
  )

  custom_robot(
    'bravo-mrna-capture-rnaa-m',
    name: 'Bravo mRNA capture RNAA (modular)',
    beds: {
      bed(7).barcode => {
        purpose: 'LBR Cherrypick',
        states: ['passed'],
        label: 'Bed 7' },
      bed(6).barcode => {
        purpose: 'LBR mRNA Cap',
        states: ['pending'],
        label: 'Bed 6',
        target_state: 'started',
        parent: bed(7).barcode },
      car('2,3').barcode => {
        purpose: 'LBR Frag',
        states: ['pending'],
        label: 'Carousel 2,3',
        parent: bed(6).barcode }
    }
  )

  bravo_robot do
    from 'PF Lib XP', bed(4)
    to 'PF Lib XP2', car('2,3')
  end

  bravo_robot transition_to: 'started' do
    from 'LBR Cherrypick', bed(7)
    to 'LBR mRNA Cap', bed(6)
  end

  custom_robot('bravo-lbr-mrna-cap',
               name: 'Bravo LBR mRNA Cap',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR mRNA Cap',
                  states: ['started'],
                  label: 'Bed 8',
                  target_state: 'passed' }
               })

  custom_robot('bravo-lbr-mrna-cap-globin',
               name: 'Bravo LBR mRNA Cap to LBR Globin',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR mRNA Cap',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('2,3').barcode => {
                  purpose: 'LBR Globin',
                  states: ['pending'],
                  label: 'Carousel 2,3',
                  parent: bed(8).barcode,
                  target_state: 'processed_1' }
               })

  custom_robot(
    'bravo-hyb-setup',
    name: 'Bravo Hyb Setup',
    beds: {
      bed(6).barcode => {
        purpose: 'LBR Globin',
        states: ['processed_1'],
        label: 'Bed 6',
        target_state: 'processed_2' },
      car('4,3').barcode => {
        purpose: 'LBR Globin DNase',
        states: ['pending'],
        label: 'Carousel 4,3',
        parent: bed(6).barcode },
      car('4,4').barcode => {
        purpose: 'LBR Frag cDNA',
        states: ['pending'],
        label: 'Carousel 4,4',
        parent: car('4,3').barcode }
    }
  )

  custom_robot(
    'bravo-ribo-hyb-setup',
    name: 'Bravo Ribo Hyb Setup',
    beds: {
      bed(6).barcode => {
        purpose: 'LBR Cherrypick',
        states: ['passed'],
        label: 'Bed 6' },
      car('4,3').barcode => {
        purpose: 'LBR Ribo DNase',
        states: ['pending'],
        label: 'Carousel 4,3',
        parent: bed(6).barcode },
      car('4,4').barcode => {
        purpose: 'LBR Frag cDNA',
        states: ['pending'],
        label: 'Carousel 4,4',
        parent: car('4,3').barcode }
    }
  )

  custom_robot(
    'bravo-riboglobin-hyb-setup',
    name: 'Bravo Ribo Globin Hyb Setup',
    beds: {
      bed(6).barcode => {
        purpose: 'LBR Cherrypick',
        states: ['passed'],
        label: 'Bed 6' },
      car('4,3').barcode => {
        purpose: 'LBR RiboGlobin DNase',
        states: ['pending'],
        label: 'Carousel 4,3',
        parent: bed(6).barcode },
      car('4,4').barcode => {
        purpose: 'LBR Frag cDNA',
        states: ['pending'],
        label: 'Carousel 4,4',
        parent: car('4,3').barcode }
    }
  )

  custom_robot('bravo-depletion-setup',
               name: 'Bravo Depletion Setup',
               verify_robot: true,
               beds: {
                 bed(6).barcode => {
                  purpose: 'LBR Globin',
                  states: ['processed_2'],
                  label: 'Bed 6',
                  target_state: 'passed' }
               })

  custom_robot('bravo-ribo-depletion-setup',
               name: 'Bravo Ribo Depletion Setup',
               verify_robot: true,
               beds: {
                 bed(6).barcode => {
                  purpose: 'LBR Cherrypick',
                  states: ['passed'],
                  label: 'Bed 6' }
               })

  custom_robot('bravo-riboglobin-depletion-setup',
               name: 'Bravo Ribo Globin Depletion Setup',
               verify_robot: true,
               beds: {
                 bed(6).barcode => {
                  purpose: 'LBR Cherrypick',
                  states: ['passed'],
                  label: 'Bed 6' }
               })

  custom_robot('bravo-globin-globin-dnase',
               name: 'Bravo Globin To Globin DNase',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Globin',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,3').barcode => {
                  purpose: 'LBR Globin DNase',
                  states: ['pending'],
                  label: 'Carousel 4,3',
                  parent: bed(8).barcode,
                  target_state: 'passed' }
               })

  custom_robot('bravo-ribo-dnase',
               name: 'Bravo Cherrypick To Ribo DNase',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Cherrypick',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,3').barcode => {
                  purpose: 'LBR Ribo DNase',
                  states: ['pending'],
                  label: 'Carousel 4,3',
                  parent: bed(8).barcode,
                  target_state: 'passed' }
               })

  custom_robot('bravo-riboglobin-dnase',
               name: 'Bravo Cherrypick To Ribo Globin DNase',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Cherrypick',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,3').barcode => {
                  purpose: 'LBR RiboGlobin DNase',
                  states: ['pending'],
                  label: 'Carousel 4,3',
                  parent: bed(8).barcode,
                  target_state: 'passed' }
               })

  custom_robot('bravo-lbr-globin-dnase-frag-cdna',
               name: 'Bravo LBR Globin DNase To LBR Frag cDNA',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Globin DNase',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,4').barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['pending'],
                  label: 'Carousel 4,4',
                  parent: bed(8).barcode,
                  target_state: 'processed_1' }
               })

  custom_robot('bravo-lbr-ribo-dnase-frag-cdna',
               name: 'Bravo LBR Ribo DNase To LBR Frag cDNA',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Ribo DNase',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,4').barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['pending'],
                  label: 'Carousel 4,4',
                  parent: bed(8).barcode,
                  target_state: 'processed_1' }
               })

  custom_robot('bravo-lbr-riboglobin-dnase-frag-cdna',
               name: 'Bravo LBR Ribo Globin DNase To LBR Frag cDNA',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR RiboGlobin DNase',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,4').barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['pending'],
                  label: 'Carousel 4,4',
                  parent: bed(8).barcode,
                  target_state: 'processed_1' }
               })

  custom_robot('bravo-strand-setup',
               name: 'Bravo Strand Setup',
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['processed_1'],
                  label: 'Bed 8',
                  target_state: 'processed_2' },
                 car('4,3').barcode => {
                  purpose: 'LB cDNA XP',
                  states: ['pending'],
                  label: 'Carousel 4,3',
                  parent: bed(8).barcode }
               })

  custom_robot('bravo-strand-setup-rnaa-m',
               name: 'Bravo Strand Setup RNAA (modular)',
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('3,4').barcode => {
                  purpose: 'LB cDNA',
                  states: ['pending'],
                  label: 'Carousel 3,4',
                  parent: bed(8).barcode },
                 car('4,3').barcode => {
                  purpose: 'LB cDNA XP',
                  states: ['pending'],
                  label: 'Carousel 4,3',
                  parent: car('3,4').barcode }
               })

  custom_robot('bravo-second-strand-setup',
               name: 'Bravo Second Strand Setup',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['processed_2'],
                  label: 'Bed 8',
                  target_state: 'passed' }
               })

  custom_robot('bravo-lbr-frag-lb-cdna-xp',
               name: 'Bravo LBR Frag To LB cDNA XP',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LBR Frag cDNA',
                  states: ['passed'],
                  label: 'Bed 8' },
                 car('4,3').barcode => {
                  purpose: 'LB cDNA XP',
                  states: ['pending'],
                  label: 'Carousel 4,3',
                  parent: bed(8).barcode,
                  target_state: 'passed' }
               })

  bravo_robot do
    from 'LBR mRNA Cap', bed(8)
    to 'LBR Frag', car('2,3')
  end

  bravo_robot transition_to: 'started' do
    from 'LBR Frag', bed(8)
    to 'LB cDNA', car('3,4')
  end

  custom_robot('bravo-lb-cdna',
               name: 'Bravo LB cDNA',
               verify_robot: true,
               beds: {
                 bed(8).barcode => {
                  purpose: 'LB cDNA',
                  states: ['started'],
                  label: 'Bed 8',
                  target_state: 'passed' }
               })

  bravo_robot do
    from 'LB cDNA', bed(8)
    to 'LB cDNA XP', car('4,3')
  end

  bravo_robot transition_to: 'started' do
    from 'LB cDNA XP', bed(7)
    to 'LB End Prep', car('1,4')
  end

  simple_robot('mosquito', transition_to: 'started') do
    from 'GBS PCR1', bed(1)
    to 'GBS PCR2', bed(2)
  end

  custom_robot(
    'mosquito-gbs-pcr1-to-gbs-pcr2',
    name: 'mosquito GBS PCR1 => GBS PCR2',
    beds: {
      bed(1).barcode => {
        purpose: 'GBS PCR1',
        states: ['passed'],
        label: 'Bed 1' },
      bed(2).barcode => {
        purpose: 'GBS PCR2',
        states: ['pending'],
        label: 'Bed 2',
        parent: bed(1).barcode,
        target_state: 'started' },
      bed(4).barcode => {
        purpose: 'GBS PCR1',
        states: ['passed'],
        label: 'Bed 4' },
      bed(5).barcode => {
        purpose: 'GBS PCR2',
        states: ['pending'],
        label: 'Bed 5',
        parent: bed(4).barcode,
        target_state: 'started' }
    }
  )

  custom_robot(
    'mosquito-gbs-96-stock-to-gbs-pcr1',
    name: 'Mosquito GBS-96 Stock => GBS PCR1',
    beds: {
     bed(1).barcode => {
      purpose: 'GBS-96 Stock',
      states: %w[passed qc_complete], child: bed(5).barcode,
      label: 'Bed 1' },
     bed(2).barcode => {
      purpose: 'GBS-96 Stock',
      states: %w[passed qc_complete], child: bed(5).barcode,
      label: 'Bed 2' },
     bed(3).barcode => {
      purpose: 'GBS-96 Stock',
      states: %w[passed qc_complete], child: bed(5).barcode,
      label: 'Bed 3' },
     bed(4).barcode => {
      purpose: 'GBS-96 Stock',
      states: %w[passed qc_complete], child: bed(5).barcode,
      label: 'Bed 4' },
     bed(5).barcode => {
       purpose: 'GBS PCR1',
       states: %w[pending],
       parents: [bed(1).barcode, bed(2).barcode, bed(3).barcode, bed(4).barcode],
       target_state: 'passed',
       label: 'Bed 5'
     }
    },
    destination_bed: bed(5).barcode,
    class: 'Robots::QuadrantRobot'
  )

  # GnT Stuff, might change a lot.
  custom_robot(
    'hamilton-gnt-stock-to-gnt-scdna-stock',
    name: 'Hamilton GnT Stock => GnT scDNA and scRNA',
    beds: {
      bed(3).barcode => {
        purpose: 'GnT Stock',
        states: ['passed'],
        label: 'Bed 1' },
      bed(10).barcode => {
        purpose: 'GnT scDNA',
        states: ['pending'],
        label: 'Bed 10',
        parent: bed(3).barcode,
        target_state: 'started' }
    }
  )

  custom_robot(
    'hamilton-gnt-scdna-stock',
    name: 'Hamilton GnT scDNA',
    verify_robot: true,
    beds: {
      bed(10).barcode => {
        purpose: 'GnT scDNA',
        states: ['started'],
        label: 'Bed 10',
        target_state: 'passed' }
    }
  )

  bravo_robot transition_to: 'started' do
    from 'GnT Pico-XP', bed(4)
    to 'GnT Pico End Prep', car('1,4')
  end

  custom_robot('bravo-pico-end-prep',
               name: 'bravo GnT Pico End Prep',
               verify_robot: true,
               beds: {
                 bed(5).barcode => {
                  purpose: 'GnT Pico End Prep',
                  states: ['started'],
                  label: 'Bed 5',
                  target_state: 'passed' }
               })

  bravo_robot do
    from 'GnT Pico End Prep', car('1,4')
    to 'GnT Pico Lib PCR', bed(6)
  end

  bravo_robot do
    from 'GnT scDNA', bed(4)
    to 'GnT Pico-XP', car('2,3')
  end

  bravo_robot do
    from 'GnT scDNA', bed(4)
    to 'GnT MDA Norm', car('2,3')
  end

  # For Chromium 10x pipeline aggregation to cherrypick
  custom_robot('hamilton-lbc-aggregate-to-lbc-cherrypick',
               name: 'hamilton LBC Aggregate => LBC Cherrypick',
               beds: {
                 bed(1).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 1' },
                 bed(2).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 2' },
                 bed(3).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 3' },
                 bed(4).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 4' },
                 bed(5).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 5' },
                 bed(6).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 6' },
                 bed(7).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 7' },
                 bed(8).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 8' },
                 bed(9).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 9' },
                 bed(10).barcode => {
                   purpose: 'LBC Aggregate',
                   states: %w[passed qc_complete],
                   child: bed(13).barcode,
                   label: 'Bed 10' },
                 bed(13).barcode => {
                   purpose: 'LBC Cherrypick',
                   states: %w[pending started],
                   parents: [
                     bed(1).barcode,
                     bed(2).barcode,
                     bed(3).barcode,
                     bed(4).barcode,
                     bed(5).barcode,
                     bed(6).barcode,
                     bed(7).barcode,
                     bed(8).barcode,
                     bed(9).barcode,
                     bed(10).barcode
                   ],
                   target_state: 'passed',
                   label: 'Bed 13'
                 }
               },
               destination_bed: bed(13).barcode,
               class: 'Robots::PoolingRobot')

  # For Chromium 10x pipeline cherrypick to dilution
  custom_robot(
    'hamilton-lbc-cherrypick-to-lbc-3pv3-gex-dil',
    name: 'hamilton LBC Cherrypick => LBC 3pV3 GEX Dil',
    beds: {
      bed(13).barcode => {
        purpose: 'LBC Cherrypick',
        states: ['passed'],
        label: 'Bed 13' },
      bed(1).barcode => {
        purpose: 'LBC 3pV3 GEX Dil',
        states: ['pending'],
        label: 'Bed 1',
        target_state: 'passed',
        parent: bed(13).barcode
      }
    }
  )

  # For Chromium 10x pipeline dilution to frag 2xp
  custom_robot(
    'hamilton-lbc-3pv3-gex-dil-to-lbc-3pv3-gex-frag-2xp',
    name: 'hamilton LBC 3pV3 GEX Dil => LBC 3pV3 GEX Frag 2XP',
    beds: {
      bed(13).barcode => {
        purpose: 'LBC 3pV3 GEX Dil',
        states: ['passed'],
        label: 'Bed 13' },
      bed(3).barcode => {
        purpose: 'LBC 3pV3 GEX Frag 2XP',
        states: ['pending'],
        label: 'Bed 3',
        target_state: 'passed',
        parent: bed(13).barcode
      }
    }
  )

  # For Chromium 10x pipeline frag 2xp to ligxp
  custom_robot(
    'hamilton-lbc-3pv3-gex-frag-2xp-to-lbc-3pv3-gex-ligxp',
    name: 'hamilton LBC 3pV3 GEX Frag 2XP => LBC 3pV3 GEX LigXP',
    beds: {
      bed(13).barcode => {
        purpose: 'LBC 3pV3 GEX Frag 2XP',
        states: ['passed'],
        label: 'Bed 13' },
      bed(3).barcode => {
        purpose: 'LBC 3pV3 GEX LigXP',
        states: ['pending'],
        label: 'Bed 3',
        target_state: 'passed',
        parent: bed(13).barcode
      }
    }
  )
end
