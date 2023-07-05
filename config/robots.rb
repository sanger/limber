# frozen_string_literal: true

require 'robot_configuration'

ROBOT_CONFIG =
  RobotConfiguration::Register.configure do
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

    custom_robot(
      'bravo-lb-end-prep',
      name: 'bravo LB End Prep',
      verify_robot: true,
      beds: {
        bed(7).barcode => {
          purpose: 'LB End Prep',
          states: ['started'],
          label: 'Bed 7',
          target_state: 'passed'
        }
      }
    )

    bravo_robot do
      from 'LB End Prep', bed(7)
      to 'LB Lib PCR', bed(6)
    end

    custom_robot(
      'bravo-lib-pcr-purification',
      name: 'bravo LB Lib PCR => LB Lib PCR XP',
      verify_robot: false,
      beds: {
        bed(1).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 1'
        },
        bed(9).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 9',
          parent: bed(1).barcode,
          target_state: 'passed'
        },
        bed(2).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(10).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 10',
          parent: bed(2).barcode,
          target_state: 'passed'
        },
        bed(3).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 3'
        },
        bed(11).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 11',
          parent: bed(3).barcode,
          target_state: 'passed'
        },
        bed(4).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(12).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 12',
          parent: bed(4).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'star-96-lib-pcr-purification',
      name: 'STAR-96 LB Lib PCR => LB Lib PCR-XP',
      verify_robot: false,
      beds: {
        bed(7).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(9).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 9',
          parent: bed(7).barcode,
          target_state: 'passed'
        },
        bed(12).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 12'
        },
        bed(14).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 14',
          parent: bed(12).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'zephyr-lib-pcr-purification',
      name: 'Zephyr LB Lib PCR => LB Lib PCR XP',
      verify_robot: false,
      beds: {
        bed(2).barcode => {
          purpose: 'LB Lib PCR',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(7).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 7',
          parent: bed(2).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'nx-8-lib-pcr-xp-to-isch-lib-pool',
      name: 'nx-8 Lib PCR-XP => LB Lib PrePool',
      beds: {
        bed(2).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: %w[passed qc_complete],
          child: bed(4).barcode,
          label: 'Bed 2'
        },
        bed(5).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: %w[passed qc_complete],
          child: bed(4).barcode,
          label: 'Bed 5'
        },
        bed(3).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: %w[passed qc_complete],
          child: bed(4).barcode,
          label: 'Bed 3'
        },
        bed(6).barcode => {
          purpose: 'LB Lib PCR-XP',
          states: %w[passed qc_complete],
          child: bed(4).barcode,
          label: 'Bed 6'
        },
        bed(4).barcode => {
          purpose: 'LB Lib PrePool',
          states: %w[pending started],
          parents: [
            bed(2).barcode,
            bed(5).barcode,
            bed(3).barcode,
            bed(6).barcode,
            bed(2).barcode,
            bed(5).barcode,
            bed(3).barcode,
            bed(6).barcode
          ],
          target_state: 'passed',
          label: 'Bed 4'
        }
      },
      destination_bed: bed(4).barcode,
      class: 'Robots::PoolingRobot'
    )

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

    custom_robot(
      'star-96-post-cap-pcr-purification',
      name: 'STAR-96 LB Cap Lib PCR => LB Cap Lib PCR-XP',
      verify_robot: false,
      beds: {
        bed(7).barcode => {
          purpose: 'LB Cap Lib PCR',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(9).barcode => {
          purpose: 'LB Cap Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 9',
          parent: bed(7).barcode,
          target_state: 'passed'
        },
        bed(12).barcode => {
          purpose: 'LB Cap Lib PCR',
          states: ['passed'],
          label: 'Bed 12'
        },
        bed(14).barcode => {
          purpose: 'LB Cap Lib PCR-XP',
          states: ['pending'],
          label: 'Bed 14',
          parent: bed(12).barcode,
          target_state: 'passed'
        }
      }
    )

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
          label: 'Bed 1'
        },
        bed(9).barcode => {
          purpose: 'PF Post Shear XP',
          states: ['pending'],
          label: 'Bed 9',
          parent: bed(1).barcode,
          target_state: 'started'
        },
        bed(2).barcode => {
          purpose: 'PF Post Shear',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(10).barcode => {
          purpose: 'PF Post Shear XP',
          states: ['pending'],
          label: 'Bed 10',
          parent: bed(2).barcode,
          target_state: 'started'
        },
        bed(3).barcode => {
          purpose: 'PF Post Shear',
          states: ['passed'],
          label: 'Bed 3'
        },
        bed(11).barcode => {
          purpose: 'PF Post Shear XP',
          states: ['pending'],
          label: 'Bed 11',
          parent: bed(3).barcode,
          target_state: 'started'
        },
        bed(4).barcode => {
          purpose: 'PF Post Shear',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(12).barcode => {
          purpose: 'PF Post Shear XP',
          states: ['pending'],
          label: 'Bed 12',
          parent: bed(4).barcode,
          target_state: 'started'
        }
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
          label: 'Bed 12'
        },
        bed(17).barcode => {
          purpose: 'scRNA-384 cDNA-XP',
          states: ['pending'],
          label: 'Bed 17',
          parent: bed(12).barcode,
          target_state: 'passed'
        },
        bed(13).barcode => {
          purpose: 'scRNA-384 Stock',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(18).barcode => {
          purpose: 'scRNA-384 cDNA-XP',
          states: ['pending'],
          label: 'Bed 18',
          parent: bed(13).barcode,
          target_state: 'passed'
        },
        bed(14).barcode => {
          purpose: 'scRNA-384 Stock',
          states: ['passed'],
          label: 'Bed 14'
        },
        bed(19).barcode => {
          purpose: 'scRNA-384 cDNA-XP',
          states: ['pending'],
          label: 'Bed 19',
          parent: bed(14).barcode,
          target_state: 'passed'
        },
        bed(15).barcode => {
          purpose: 'scRNA-384 Stock',
          states: ['passed'],
          label: 'Bed 15'
        },
        bed(20).barcode => {
          purpose: 'scRNA-384 cDNA-XP',
          states: ['pending'],
          label: 'Bed 20',
          parent: bed(15).barcode,
          target_state: 'passed'
        }
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

    custom_robot(
      'bravo-scdna-end-prep',
      name: 'bravo scDNA End Prep',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'scRNA End Prep',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-scdna-384-end-prep',
      name: 'bravo scDNA-384 End Prep',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'scRNA-384 End Prep',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

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
          label: 'Bed 4'
        },
        car('1,4').barcode => {
          purpose: 'PF End Prep',
          states: ['pending'],
          label: 'Carousel 1,4',
          parent: bed(4).barcode,
          target_state: 'started'
        }
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
          target_state: 'passed'
        }
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
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'hamilton-star-pf-post-shear-to-pf-post-shear-xp-384',
      name: 'Hamilton STAR-384 PF-Post Shear => PF-384 Post Shear XP',
      beds: {
        bed(12).barcode => {
          purpose: 'PF Post Shear',
          states: %w[passed qc_complete],
          child: bed(7).barcode,
          label: 'Bed 12'
        },
        bed(13).barcode => {
          purpose: 'PF Post Shear',
          states: %w[passed qc_complete],
          child: bed(7).barcode,
          label: 'Bed 13'
        },
        bed(14).barcode => {
          purpose: 'PF Post Shear',
          states: %w[passed qc_complete],
          child: bed(7).barcode,
          label: 'Bed 14'
        },
        bed(15).barcode => {
          purpose: 'PF Post Shear',
          states: %w[passed qc_complete],
          child: bed(7).barcode,
          label: 'Bed 15'
        },
        bed(7).barcode => {
          purpose: 'PF-384 Post Shear XP',
          states: %w[pending],
          parents: [bed(12).barcode, bed(13).barcode, bed(14).barcode, bed(15).barcode],
          target_state: 'passed',
          label: 'Bed 7'
        }
      },
      destination_bed: bed(7).barcode,
      class: 'Robots::QuadrantRobot'
    )

    custom_robot(
      'bravo-pf-post-shear-xp-to-pf-lib-xp',
      name: 'Bravo PF Post Shear XP to PF Lib XP',
      beds: {
        car('1,3').barcode => {
          purpose: 'PF Post Shear XP',
          states: ['passed'],
          label: 'Carousel 1,3'
        },
        bed(6).barcode => {
          purpose: 'PF Lib',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: car('1,3').barcode
        },
        car('4,3').barcode => {
          purpose: 'PF Lib XP',
          states: ['pending'],
          label: 'Carousel 4,3',
          target_state: 'passed',
          parent: bed(6).barcode
        }
      }
    )

    custom_robot(
      'bravo-pf-end-prep-to-pf-lib-xp-2',
      name: 'Bravo PF End Prep to PF Lib XP2',
      beds: {
        bed(5).barcode => {
          purpose: 'PF End Prep',
          states: ['passed'],
          label: 'Bed 5'
        },
        bed(6).barcode => {
          purpose: 'PF Lib',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: bed(5).barcode
        },
        car('4,3').barcode => {
          purpose: 'PF Lib XP2',
          states: ['pending'],
          label: 'Carousel 4,3',
          target_state: 'passed',
          parent: bed(6).barcode
        }
      }
    )

    bravo_robot transition_to: 'started' do
      from 'PF-384 Post Shear XP', bed(4)
      to 'PF-384 End Prep', car('1,4')
    end

    custom_robot(
      'bravo-pf-384-end-prep',
      name: 'Bravo PF-384 End Prep End Preparation',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'PF-384 End Prep',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-pf-384-end-prep-to-pf-384-lib-xp-2',
      name: 'Bravo PF-384 End Prep to PF-384 Lib XP2',
      beds: {
        bed(5).barcode => {
          purpose: 'PF-384 End Prep',
          states: ['passed'],
          label: 'Bed 5'
        },
        bed(6).barcode => {
          purpose: 'PF-384 Lib',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: bed(5).barcode
        },
        car('4,3').barcode => {
          purpose: 'PF-384 Lib XP2',
          states: ['pending'],
          label: 'Carousel 4,3',
          target_state: 'passed',
          parent: bed(6).barcode
        }
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
      relationships: [
        {
          'type' => 'quad_stamp_out',
          'options' => {
            'parent' => bed(5).barcode,
            'children' => [bed(1).barcode, bed(4).barcode, bed(3).barcode, bed(6).barcode]
          }
        }
      ]
    )

    custom_robot(
      'bravo-mrna-capture-rnaag',
      name: 'Bravo mRNA capture RNAAG',
      beds: {
        bed(7).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(6).barcode => {
          purpose: 'LBR mRNA Cap',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'started',
          parent: bed(7).barcode
        },
        car('2,3').barcode => {
          purpose: 'LBR Globin',
          states: ['pending'],
          label: 'Carousel 2,3',
          parent: bed(6).barcode
        }
      }
    )

    custom_robot(
      'bravo-mrna-capture-rnaa',
      name: 'Bravo mRNA capture RNAA',
      beds: {
        bed(7).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(6).barcode => {
          purpose: 'LBR mRNA Cap',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'started',
          parent: bed(7).barcode
        },
        car('2,3').barcode => {
          purpose: 'LBR Frag',
          states: ['pending'],
          label: 'Carousel 2,3',
          parent: bed(6).barcode
        },
        car('3,4').barcode => {
          purpose: 'LB cDNA',
          states: ['pending'],
          label: 'Carousel 3,4',
          parent: car('2,3').barcode
        },
        car('4,3').barcode => {
          purpose: 'LB cDNA XP',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: car('3,4').barcode
        }
      }
    )

    custom_robot(
      'bravo-mrna-capture-rnaa-m',
      name: 'Bravo mRNA capture RNAA (modular)',
      beds: {
        bed(7).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(6).barcode => {
          purpose: 'LBR mRNA Cap',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'started',
          parent: bed(7).barcode
        },
        car('2,3').barcode => {
          purpose: 'LBR Frag',
          states: ['pending'],
          label: 'Carousel 2,3',
          parent: bed(6).barcode
        }
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

    custom_robot(
      'bravo-lbr-mrna-cap',
      name: 'Bravo LBR mRNA Cap',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR mRNA Cap',
          states: ['started'],
          label: 'Bed 8',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-lbr-mrna-cap-globin',
      name: 'Bravo LBR mRNA Cap to LBR Globin',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR mRNA Cap',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('2,3').barcode => {
          purpose: 'LBR Globin',
          states: ['pending'],
          label: 'Carousel 2,3',
          parent: bed(8).barcode,
          target_state: 'processed_1'
        }
      }
    )

    custom_robot(
      'bravo-hyb-setup',
      name: 'Bravo Hyb Setup',
      beds: {
        bed(6).barcode => {
          purpose: 'LBR Globin',
          states: ['processed_1'],
          label: 'Bed 6',
          target_state: 'processed_2'
        },
        car('4,3').barcode => {
          purpose: 'LBR Globin DNase',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(6).barcode
        },
        car('4,4').barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['pending'],
          label: 'Carousel 4,4',
          parent: car('4,3').barcode
        }
      }
    )

    custom_robot(
      'bravo-ribo-hyb-setup',
      name: 'Bravo Ribo Hyb Setup',
      beds: {
        bed(6).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 6'
        },
        car('4,3').barcode => {
          purpose: 'LBR Ribo DNase',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(6).barcode
        },
        car('4,4').barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['pending'],
          label: 'Carousel 4,4',
          parent: car('4,3').barcode
        }
      }
    )

    custom_robot(
      'bravo-riboglobin-hyb-setup',
      name: 'Bravo Ribo Globin Hyb Setup',
      beds: {
        bed(6).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 6'
        },
        car('4,3').barcode => {
          purpose: 'LBR RiboGlobin DNase',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(6).barcode
        },
        car('4,4').barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['pending'],
          label: 'Carousel 4,4',
          parent: car('4,3').barcode
        }
      }
    )

    custom_robot(
      'bravo-depletion-setup',
      name: 'Bravo Depletion Setup',
      verify_robot: true,
      beds: {
        bed(6).barcode => {
          purpose: 'LBR Globin',
          states: ['processed_2'],
          label: 'Bed 6',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-ribo-depletion-setup',
      name: 'Bravo Ribo Depletion Setup',
      verify_robot: true,
      beds: {
        bed(6).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 6'
        }
      }
    )

    custom_robot(
      'bravo-riboglobin-depletion-setup',
      name: 'Bravo Ribo Globin Depletion Setup',
      verify_robot: true,
      beds: {
        bed(6).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 6'
        }
      }
    )

    custom_robot(
      'bravo-globin-globin-dnase',
      name: 'Bravo Globin To Globin DNase',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Globin',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,3').barcode => {
          purpose: 'LBR Globin DNase',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(8).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-ribo-dnase',
      name: 'Bravo Cherrypick To Ribo DNase',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,3').barcode => {
          purpose: 'LBR Ribo DNase',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(8).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-riboglobin-dnase',
      name: 'Bravo Cherrypick To Ribo Globin DNase',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Cherrypick',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,3').barcode => {
          purpose: 'LBR RiboGlobin DNase',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(8).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-lbr-globin-dnase-frag-cdna',
      name: 'Bravo LBR Globin DNase To LBR Frag cDNA',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Globin DNase',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,4').barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['pending'],
          label: 'Carousel 4,4',
          parent: bed(8).barcode,
          target_state: 'processed_1'
        }
      }
    )

    custom_robot(
      'bravo-lbr-ribo-dnase-frag-cdna',
      name: 'Bravo LBR Ribo DNase To LBR Frag cDNA',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Ribo DNase',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,4').barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['pending'],
          label: 'Carousel 4,4',
          parent: bed(8).barcode,
          target_state: 'processed_1'
        }
      }
    )

    custom_robot(
      'bravo-lbr-riboglobin-dnase-frag-cdna',
      name: 'Bravo LBR Ribo Globin DNase To LBR Frag cDNA',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR RiboGlobin DNase',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,4').barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['pending'],
          label: 'Carousel 4,4',
          parent: bed(8).barcode,
          target_state: 'processed_1'
        }
      }
    )

    custom_robot(
      'bravo-strand-setup',
      name: 'Bravo Strand Setup',
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['processed_1'],
          label: 'Bed 8',
          target_state: 'processed_2'
        },
        car('4,3').barcode => {
          purpose: 'LB cDNA XP',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(8).barcode
        }
      }
    )

    custom_robot(
      'bravo-strand-setup-rnaa-m',
      name: 'Bravo Strand Setup RNAA (modular)',
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('3,4').barcode => {
          purpose: 'LB cDNA',
          states: ['pending'],
          label: 'Carousel 3,4',
          parent: bed(8).barcode
        },
        car('4,3').barcode => {
          purpose: 'LB cDNA XP',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: car('3,4').barcode
        }
      }
    )

    custom_robot(
      'bravo-second-strand-setup',
      name: 'Bravo Second Strand Setup',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['processed_2'],
          label: 'Bed 8',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-lbr-frag-lb-cdna-xp',
      name: 'Bravo LBR Frag To LB cDNA XP',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LBR Frag cDNA',
          states: ['passed'],
          label: 'Bed 8'
        },
        car('4,3').barcode => {
          purpose: 'LB cDNA XP',
          states: ['pending'],
          label: 'Carousel 4,3',
          parent: bed(8).barcode,
          target_state: 'passed'
        }
      }
    )

    bravo_robot do
      from 'LBR mRNA Cap', bed(8)
      to 'LBR Frag', car('2,3')
    end

    bravo_robot transition_to: 'started' do
      from 'LBR Frag', bed(8)
      to 'LB cDNA', car('3,4')
    end

    custom_robot(
      'bravo-lb-cdna',
      name: 'Bravo LB cDNA',
      verify_robot: true,
      beds: {
        bed(8).barcode => {
          purpose: 'LB cDNA',
          states: ['started'],
          label: 'Bed 8',
          target_state: 'passed'
        }
      }
    )

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
          label: 'Bed 1'
        },
        bed(2).barcode => {
          purpose: 'GBS PCR2',
          states: ['pending'],
          label: 'Bed 2',
          parent: bed(1).barcode,
          target_state: 'started'
        },
        bed(4).barcode => {
          purpose: 'GBS PCR1',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(5).barcode => {
          purpose: 'GBS PCR2',
          states: ['pending'],
          label: 'Bed 5',
          parent: bed(4).barcode,
          target_state: 'started'
        }
      }
    )

    custom_robot(
      'mosquito-gbs-96-stock-to-gbs-pcr1',
      name: 'Mosquito GBS-96 Stock => GBS PCR1',
      beds: {
        bed(1).barcode => {
          purpose: 'GBS-96 Stock',
          states: %w[passed qc_complete],
          child: bed(3).barcode,
          label: 'Bed 1'
        },
        bed(2).barcode => {
          purpose: 'GBS-96 Stock',
          states: %w[passed qc_complete],
          child: bed(3).barcode,
          label: 'Bed 2'
        },
        bed(3).barcode => {
          purpose: 'GBS PCR1',
          states: %w[pending],
          parents: [bed(1).barcode, bed(2).barcode, bed(4).barcode, bed(5).barcode],
          target_state: 'passed',
          label: 'Bed 3'
        },
        bed(4).barcode => {
          purpose: 'GBS-96 Stock',
          states: %w[passed qc_complete],
          child: bed(3).barcode,
          label: 'Bed 4'
        },
        bed(5).barcode => {
          purpose: 'GBS-96 Stock',
          states: %w[passed qc_complete],
          child: bed(3).barcode,
          label: 'Bed 5'
        }
      },
      destination_bed: bed(3).barcode,
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
          label: 'Bed 1'
        },
        bed(10).barcode => {
          purpose: 'GnT scDNA',
          states: ['pending'],
          label: 'Bed 10',
          parent: bed(3).barcode,
          target_state: 'started'
        }
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
          target_state: 'passed'
        }
      }
    )

    bravo_robot transition_to: 'started' do
      from 'GnT Pico-XP', bed(4)
      to 'GnT Pico End Prep', car('1,4')
    end

    custom_robot(
      'bravo-pico-end-prep',
      name: 'bravo GnT Pico End Prep',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'GnT Pico End Prep',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

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
    custom_robot(
      'hamilton-lcm-lysate-to-lcm-dna',
      name: 'hamilton LCA Lysate => LCA DNA',
      beds: {
        bed(1).barcode => {
          purpose: 'Lysate LCA',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 1'
        },
        bed(2).barcode => {
          purpose: 'Lysate LCA',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 2'
        },
        bed(3).barcode => {
          purpose: 'Lysate LCA',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 3'
        },
        bed(4).barcode => {
          purpose: 'Lysate LCA',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 4'
        },
        bed(13).barcode => {
          purpose: 'Lysate DNAseq cherrypick',
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
      class: 'Robots::PoolingRobot'
    )

    # For Chromium 10x pipeline aggregation to cherrypick
    custom_robot(
      'hamilton-lbc-aggregate-to-lbc-cherrypick',
      name: 'hamilton LBC Aggregate => LBC Cherrypick',
      beds: {
        bed(1).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 1'
        },
        bed(2).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 2'
        },
        bed(3).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 3'
        },
        bed(4).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 4'
        },
        bed(5).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 5'
        },
        bed(6).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 6'
        },
        bed(7).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 7'
        },
        bed(8).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 8'
        },
        bed(9).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 9'
        },
        bed(10).barcode => {
          purpose: 'LBC Aggregate',
          states: %w[passed qc_complete],
          child: bed(13).barcode,
          label: 'Bed 10'
        },
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
      class: 'Robots::PoolingRobot'
    )

    # For Chromium 10x pipeline cherrypick to 3pv3 dilution
    custom_robot(
      'hamilton-lbc-cherrypick-to-lbc-3pv3-gex-dil',
      name: 'hamilton LBC Cherrypick => LBC 3pV3 GEX Dil',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC Cherrypick',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC 3pV3 GEX Dil',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # For Chromium 10x pipeline 3pv3 dilution to frag 2xp
    custom_robot(
      'hamilton-lbc-3pv3-gex-dil-to-lbc-3pv3-gex-frag-2xp',
      name: 'hamilton LBC 3pV3 GEX Dil => LBC 3pV3 GEX Frag 2XP',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC 3pV3 GEX Dil',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC 3pV3 GEX Frag 2XP',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # For Chromium 10x pipeline 3pv3 frag 2xp to ligxp
    custom_robot(
      'hamilton-lbc-3pv3-gex-frag-2xp-to-lbc-3pv3-gex-ligxp',
      name: 'hamilton LBC 3pV3 GEX Frag 2XP => LBC 3pV3 GEX LigXP',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC 3pV3 GEX Frag 2XP',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC 3pV3 GEX LigXP',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # For Chromium 10x pipeline cherrypick to 5p GEX Dil plate
    custom_robot(
      'hamilton-lbc-cherrypick-to-lbc-5p-gex-dil',
      name: 'hamilton LBC Cherrypick => LBC 5p GEX Dil',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC Cherrypick',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC 5p GEX Dil',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # For Chromium 10x pipeline 5p dilution to frag 2xp
    custom_robot(
      'hamilton-lbc-5p-gex-dil-to-lbc-5p-gex-frag-2xp',
      name: 'hamilton LBC 5p GEX Dil => LBC 5p GEX Frag 2XP',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC 5p GEX Dil',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC 5p GEX Frag 2XP',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # For Chromium 10x pipeline 5p frag 2xp to ligxp
    custom_robot(
      'hamilton-lbc-5p-gex-frag-2xp-to-lbc-5p-gex-ligxp',
      name: 'hamilton LBC 5p GEX Frag 2XP => LBC 5p GEX LigXP',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC 5p GEX Frag 2XP',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC 5p GEX LigXP',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # Robots for Chromium 10x pipeline 5p TCR route
    custom_robot(
      'hamilton-lbc-cherrypick-to-lbc-tcr-dil-1',
      name: 'hamilton LBC Cherrypick => LBC TCR Dil 1',
      beds: {
        bed(1).barcode => {
          purpose: 'LBC Cherrypick',
          states: ['passed'],
          label: 'Bed 1'
        },
        bed(13).barcode => {
          purpose: 'LBC TCR Dil 1',
          states: ['pending'],
          label: 'Bed 13',
          target_state: 'passed',
          parent: bed(1).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-tcr-dil-1-to-lbc-tcr-enrich1-2xspri',
      name: 'hamilton LBC TCR Dil 1 => LBC TCR Enrich1 2XSPRI',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC TCR Dil 1',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC TCR Enrich1 2XSPRI',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-tcr-enrich1-2xspri-to-lbc-tcr-enrich2-2xspri',
      name: 'hamilton LBC TCR Enrich1 2XSPRI => LBC TCR Enrich2 2XSPRI',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC TCR Enrich1 2XSPRI',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC TCR Enrich2 2XSPRI',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-tcr-enrich2-2xspri-to-lbc-tcr-dil-2',
      name: 'hamilton LBC TCR Enrich2 2XSPRI => LBC TCR Dil 2',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC TCR Enrich2 2XSPRI',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC TCR Dil 2',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-tcr-dil-2-to-lbc-tcr-post-lig-1xspri',
      name: 'hamilton LBC TCR Dil 2 => LBC TCR Post Lig 1XSPRI',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC TCR Dil 2',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC TCR Post Lig 1XSPRI',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # Robots for Chromium 10x pipeline 5p BCR route
    custom_robot(
      'hamilton-lbc-cherrypick-to-lbc-bcr-dil-1',
      name: 'hamilton LBC Cherrypick => LBC BCR Dil 1',
      beds: {
        bed(1).barcode => {
          purpose: 'LBC Cherrypick',
          states: ['passed'],
          label: 'Bed 1'
        },
        bed(13).barcode => {
          purpose: 'LBC BCR Dil 1',
          states: ['pending'],
          label: 'Bed 13',
          target_state: 'passed',
          parent: bed(1).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-bcr-dil-1-to-lbc-bcr-enrich1-2xspri',
      name: 'hamilton LBC BCR Dil 1 => LBC BCR Enrich1 2XSPRI',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC BCR Dil 1',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC BCR Enrich1 2XSPRI',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-bcr-enrich1-2xspri-to-lbc-bcr-enrich2-2xspri',
      name: 'hamilton LBC BCR Enrich1 2XSPRI => LBC BCR Enrich2 2XSPRI',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC BCR Enrich1 2XSPRI',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC BCR Enrich2 2XSPRI',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-bcr-enrich2-2xspri-to-lbc-bcr-dil-2',
      name: 'hamilton LBC BCR Enrich2 2XSPRI => LBC BCR Dil 2',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC BCR Enrich2 2XSPRI',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC BCR Dil 2',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lbc-bcr-dil-2-to-lbc-bcr-post-lig-1xspri',
      name: 'hamilton LBC BCR Dil 2 => LBC BCR Post Lig 1XSPRI',
      beds: {
        bed(13).barcode => {
          purpose: 'LBC BCR Dil 2',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LBC BCR Post Lig 1XSPRI',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # duplex seq
    custom_robot(
      'hamilton-lds-al-lib-to-lds-al-lib-dil',
      name: 'hamilton LDS AL Lib => LDS AL Lib Dil',
      beds: {
        bed(13).barcode => {
          purpose: 'LDS AL Lib',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LDS AL Lib Dil',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    # targeted nanoseq
    custom_robot(
      'hamilton-ltn-al-lib-to-ltn-al-lib-dil',
      name: 'hamilton LTN AL Lib => LTN AL Lib Dil',
      beds: {
        bed(13).barcode => {
          purpose: 'LTN AL Lib',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(3).barcode => {
          purpose: 'LTN AL Lib Dil',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(13).barcode
        }
      }
    )

    custom_robot(
      'bravo-ltn-cherrypick-to-ltn-shear',
      name: 'bravo LTN Cherrypick => LTN Shear',
      beds: {
        bed(7).barcode => {
          purpose: 'LTN Cherrypick',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(9).barcode => {
          purpose: 'LTN Shear',
          states: ['pending'],
          label: 'Bed 9',
          target_state: 'passed',
          parent: bed(7).barcode
        }
      }
    )

    custom_robot(
      'bravo-ltn-shear-to-ltn-post-shear',
      name: 'bravo LTN Shear => LTN Post Shear',
      beds: {
        bed(9).barcode => {
          purpose: 'LTN Shear',
          states: ['passed'],
          label: 'Bed 9'
        },
        bed(7).barcode => {
          purpose: 'LTN Post Shear',
          states: ['pending'],
          label: 'Bed 7',
          target_state: 'passed',
          parent: bed(9).barcode
        }
      }
    )

    custom_robot(
      'bravo-lhr-rt-to-pcr-1-and-2',
      name: 'Bravo LHR RT => LHR PCR 1 and 2',
      beds: {
        bed(9).barcode => {
          purpose: 'LHR RT',
          states: ['passed'],
          label: 'Bed 9'
        },
        bed(4).barcode => {
          purpose: 'LHR PCR 1',
          states: ['pending'],
          label: 'Bed 4',
          target_state: 'passed',
          parent: bed(9).barcode
        },
        bed(6).barcode => {
          purpose: 'LHR PCR 2',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: bed(9).barcode
        }
      }
    )

    custom_robot(
      'nx-96-lhr-pcr-1-and-2-to-lhr-xp',
      name: 'NX-96 LHR PCR 1 and 2 => LHR XP',
      beds: {
        bed(1).barcode => {
          purpose: 'LHR PCR 1',
          states: ['passed'],
          label: 'Bed 1',
          child: bed(9).barcode
        },
        bed(2).barcode => {
          purpose: 'LHR PCR 2',
          states: ['passed'],
          label: 'Bed 2',
          child: bed(9).barcode
        },
        bed(3).barcode => {
          purpose: 'LHR PCR 1',
          states: ['passed'],
          label: 'Bed 3',
          child: bed(11).barcode
        },
        bed(4).barcode => {
          purpose: 'LHR PCR 2',
          states: ['passed'],
          label: 'Bed 4',
          child: bed(11).barcode
        },
        bed(9).barcode => {
          purpose: 'LHR XP',
          label: 'Bed 9',
          states: ['pending'],
          target_state: 'passed',
          parents: [bed(1).barcode, bed(2).barcode]
        },
        bed(11).barcode => {
          purpose: 'LHR XP',
          label: 'Bed 11',
          states: ['pending'],
          target_state: 'passed',
          parents: [bed(3).barcode, bed(4).barcode]
        }
      }
    )

    bravo_robot transition_to: 'started', require_robot: true do
      from 'LHR XP', bed(4)
      to 'LHR End Prep', car('1,4')
    end

    custom_robot(
      'bravo-lhr-end-prep',
      name: 'bravo LHR End Prep',
      verify_robot: true,
      beds: {
        bed(7).barcode => {
          purpose: 'LHR End Prep',
          states: ['started'],
          label: 'Bed 7',
          target_state: 'passed'
        }
      }
    )

    bravo_robot verify_robot: true do
      from 'LHR End Prep', car('1,4')
      to 'LHR Lib PCR', bed(6)
    end

    custom_robot(
      'bravo-lhr-384-rt-to-lhr-384-pcr-1-and-2',
      name: 'bravo LHR-384 RT => LHR-384 PCR 1 and 2',
      beds: {
        bed(9).barcode => {
          purpose: 'LHR-384 RT',
          states: ['passed'],
          label: 'Bed 9'
        },
        bed(4).barcode => {
          purpose: 'LHR-384 PCR 1',
          states: ['pending'],
          label: 'Bed 4',
          target_state: 'passed',
          parent: bed(9).barcode
        },
        bed(6).barcode => {
          purpose: 'LHR-384 PCR 2',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: bed(9).barcode
        }
      }
    )

    custom_robot(
      'mosquito-lhr-384-pcr-1-and-2-to-lhr-384-cdna',
      name: 'mosquito LHR-384 PCR 1 and 2 => LHR-384 cDNA',
      beds: {
        bed(1).barcode => {
          purpose: 'LHR-384 PCR 1',
          states: ['passed'],
          label: 'Bed 1'
        },
        bed(2).barcode => {
          purpose: 'LHR-384 PCR 2',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(4).barcode => {
          purpose: 'LHR-384 cDNA',
          states: ['pending'],
          label: 'Bed 4',
          parents: [bed(1).barcode, bed(2).barcode],
          target_state: 'passed'
        }
      }
    )

    # allows for up to four pairs of plates to be processed simultaneously
    custom_robot(
      'hamilton-lhr-384-cdna-to-lhr-384-xp',
      name: 'hamilton LHR-384 cDNA => LHR-384 XP',
      beds: {
        bed(12).barcode => {
          purpose: 'LHR-384 cDNA',
          states: ['passed'],
          label: 'Bed 12'
        },
        bed(17).barcode => {
          purpose: 'LHR-384 XP',
          states: ['pending'],
          label: 'Bed 17',
          parent: bed(12).barcode,
          target_state: 'passed'
        },
        bed(13).barcode => {
          purpose: 'LHR-384 cDNA',
          states: ['passed'],
          label: 'Bed 13'
        },
        bed(18).barcode => {
          purpose: 'LHR-384 XP',
          states: ['pending'],
          label: 'Bed 18',
          parent: bed(13).barcode,
          target_state: 'passed'
        },
        bed(14).barcode => {
          purpose: 'LHR-384 cDNA',
          states: ['passed'],
          label: 'Bed 14'
        },
        bed(19).barcode => {
          purpose: 'LHR-384 XP',
          states: ['pending'],
          label: 'Bed 19',
          parent: bed(14).barcode,
          target_state: 'passed'
        },
        bed(15).barcode => {
          purpose: 'LHR-384 cDNA',
          states: ['passed'],
          label: 'Bed 15'
        },
        bed(20).barcode => {
          purpose: 'LHR-384 XP',
          states: ['pending'],
          label: 'Bed 20',
          parent: bed(15).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-setup-lhr-384-xp-to-lhr-384-end-prep-to-lhr-384-al-lib',
      name: 'bravo Setup LHR-384 XP, End Prep and AL Lib',
      require_robot: true,
      beds: {
        bed(4).barcode => {
          purpose: 'LHR-384 XP',
          states: ['passed'],
          label: 'Bed 4'
        },
        car('1,4').barcode => {
          purpose: 'LHR-384 End Prep',
          states: ['pending'],
          label: 'Carousel 1,4',
          target_state: 'started'
        },
        car('3,5').barcode => {
          purpose: 'LHR-384 AL Lib',
          states: ['pending'],
          label: 'Carousel 3,5',
          target_state: 'started'
        }
      }
    )

    custom_robot(
      'bravo-lhr-384-end-prep',
      name: 'bravo LHR-384 End Prep',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'LHR-384 End Prep',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-setup-lhr-384-al-lib',
      name: 'bravo Setup Library LHR-384 AL Lib',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'LHR-384 AL Lib',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-lhr-384-al-lib-to-lhr-384-lib-pcr',
      name: 'bravo Library PCR LHR-384 AL Lib => LHR-384 Lib PCR',
      verify_robot: true,
      beds: {
        bed(7).barcode => {
          purpose: 'LHR-384 AL Lib',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(6).barcode => {
          purpose: 'LHR-384 Lib PCR',
          states: ['pending'],
          label: 'Bed 6',
          parent: bed(7).barcode,
          target_state: 'passed'
        }
      }
    )

    # Heron LTHR 384 Pipeline

    custom_robot(
      'bravo-lthr-cherrypick-to-lthr-384-rt-q',
      name: 'Bravo LTHR Cherrypick => LTHR-384 RT-Q',
      beds: {
        bed(1).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 1'
        },
        bed(4).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 4'
        },
        bed(3).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 3'
        },
        bed(6).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 6'
        },
        bed(5).barcode => {
          purpose: 'LTHR-384 RT-Q',
          states: ['pending'],
          label: 'Bed 5',
          parents: [bed(1).barcode, bed(4).barcode, bed(3).barcode, bed(6).barcode],
          target_state: 'passed'
        }
      },
      destination_bed: bed(5).barcode,
      class: 'Robots::QuadrantRobot'
    )

    # alternative hamilton robot added for surge testing
    custom_robot(
      'hamilton-lthr-cherrypick-to-lthr-384-rt-q',
      name: 'Hamilton LTHR Cherrypick => LTHR-384 RT-Q',
      beds: {
        bed(5).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(2).barcode,
          label: 'Bed 5'
        },
        bed(6).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(2).barcode,
          label: 'Bed 6'
        },
        bed(7).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(2).barcode,
          label: 'Bed 7'
        },
        bed(8).barcode => {
          purpose: 'LTHR Cherrypick',
          states: ['passed'],
          child: bed(2).barcode,
          label: 'Bed 8'
        },
        bed(2).barcode => {
          purpose: 'LTHR-384 RT-Q',
          states: ['pending'],
          label: 'Bed 2',
          parents: [bed(5).barcode, bed(6).barcode, bed(7).barcode, bed(8).barcode],
          target_state: 'passed'
        }
      },
      destination_bed: bed(2).barcode,
      class: 'Robots::QuadrantRobot'
    )

    custom_robot(
      'bravo-lthr-384-rt-to-lthr-384-pcr-1-and-2',
      name: 'bravo LTHR-384 RT => LTHR-384 PCR 1 and 2',
      beds: {
        bed(9).barcode => {
          purpose: ['LTHR-384 RT', 'LTHR-384 RT-Q'],
          states: ['passed'],
          label: 'Bed 9'
        },
        bed(4).barcode => {
          purpose: 'LTHR-384 PCR 1',
          states: ['pending'],
          label: 'Bed 4',
          target_state: 'passed',
          parent: bed(9).barcode
        },
        bed(6).barcode => {
          purpose: 'LTHR-384 PCR 2',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: bed(9).barcode
        }
      }
    )

    custom_robot(
      'hamilton-lthr-384-rt-to-lthr-384-pcr-1-and-2',
      name: 'Hamilton LTHR-384 RT => LTHR-384 PCR 1 and 2',
      beds: {
        bed(2).barcode => {
          purpose: ['LTHR-384 RT', 'LTHR-384 RT-Q'],
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(1).barcode => {
          purpose: 'LTHR-384 PCR 1',
          states: ['pending'],
          label: 'Bed 1',
          target_state: 'passed',
          parent: bed(2).barcode
        },
        bed(3).barcode => {
          purpose: 'LTHR-384 PCR 2',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(2).barcode
        }
      }
    )

    custom_robot(
      'mosquito-lthr-384-pcr-1-and-2-to-lthr-384-lib-pcr-1-and-2',
      name: 'Mosquito LV LTHR-384 PCR 1 and 2 => LTHR-384 Lib PCR 1 and 2',
      beds: {
        bed(2).barcode => {
          purpose: 'LTHR-384 PCR 1',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(4).barcode => {
          purpose: 'LTHR-384 PCR 2',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(3).barcode => {
          purpose: 'LTHR-384 Lib PCR 1',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(2).barcode
        },
        bed(5).barcode => {
          purpose: 'LTHR-384 Lib PCR 2',
          states: ['pending'],
          label: 'Bed 5',
          target_state: 'passed',
          parent: bed(4).barcode
        }
      }
    )

    custom_robot(
      'bravo-lthr-384-pcr-1-and-2-to-lthr-384-lib-pcr-pool',
      name: 'bravo LTHR-384 Lib PCR 1 and 2 => LTHR-384 Lib PCR pool',
      beds: {
        bed(4).barcode => {
          purpose: 'LTHR-384 Lib PCR 1',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(6).barcode => {
          purpose: 'LTHR-384 Lib PCR 2',
          states: ['passed'],
          label: 'Bed 6'
        },
        bed(8).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['pending'],
          label: 'Bed 8',
          parents: [bed(4).barcode, bed(6).barcode],
          target_state: 'passed'
        }
      }
    )

    # alternative hamilton robot added for surge testing
    custom_robot(
      'hamilton-lthr-384-pcr-1-and-2-to-lthr-384-lib-pcr-pool',
      name: 'Hamilton LTHR-384 Lib PCR 1 and 2 => LTHR-384 Lib PCR pool',
      beds: {
        bed(1).barcode => {
          purpose: 'LTHR-384 Lib PCR 1',
          states: ['passed'],
          label: 'Bed 1'
        },
        bed(3).barcode => {
          purpose: 'LTHR-384 Lib PCR 2',
          states: ['passed'],
          label: 'Bed 3'
        },
        bed(2).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['pending'],
          label: 'Bed 2',
          parents: [bed(1).barcode, bed(3).barcode],
          target_state: 'passed'
        }
      }
    )

    # hamilton robot added for surge testing
    custom_robot(
      'hamilton-lthr-384-lib-pcr-pool-to-lthr-384-pool-xp',
      name: 'Hamilton LTHR-384 Lib PCR pool => LTHR-384 Pool XP',
      beds: {
        bed(16).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['passed'],
          label: 'Bed 16'
        },
        bed(22).barcode => {
          purpose: 'LTHR-384 Pool XP',
          states: ['pending'],
          label: 'Bed 22',
          parents: [bed(16).barcode, bed(28).barcode],
          target_state: 'passed'
        },
        bed(17).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['passed'],
          label: 'Bed 17'
        },
        bed(23).barcode => {
          purpose: 'LTHR-384 Pool XP',
          states: ['pending'],
          label: 'Bed 23',
          parents: [bed(17).barcode, bed(28).barcode],
          target_state: 'passed'
        },
        bed(18).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['passed'],
          label: 'Bed 18'
        },
        bed(24).barcode => {
          purpose: 'LTHR-384 Pool XP',
          states: ['pending'],
          label: 'Bed 24',
          parents: [bed(18).barcode, bed(28).barcode],
          target_state: 'passed'
        },
        bed(19).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['passed'],
          label: 'Bed 19'
        },
        bed(25).barcode => {
          purpose: 'LTHR-384 Pool XP',
          states: ['pending'],
          label: 'Bed 25',
          parents: [bed(19).barcode, bed(28).barcode],
          target_state: 'passed'
        },
        bed(20).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['passed'],
          label: 'Bed 20'
        },
        bed(26).barcode => {
          purpose: 'LTHR-384 Pool XP',
          states: ['pending'],
          label: 'Bed 26',
          parents: [bed(20).barcode, bed(28).barcode],
          target_state: 'passed'
        },
        bed(21).barcode => {
          purpose: 'LTHR-384 Lib PCR pool',
          states: ['passed'],
          label: 'Bed 21'
        },
        bed(27).barcode => {
          purpose: 'LTHR-384 Pool XP',
          states: ['pending'],
          label: 'Bed 27',
          parents: [bed(21).barcode, bed(28).barcode],
          target_state: 'passed'
        },
        #  PhiX bed location, shared parent for all XP tubes in this run
        bed(28).barcode => {
          purpose: 'PhiX Spiked Buffer',
          shared_parent: true,
          states: ['pending'],
          label: 'Bed 28'
        }
      }
    )

    # Heron LTHR 96 Pipeline

    bravo_robot do
      from 'LTHR Cherrypick', bed(1)
      to 'LTHR RT-S', bed(5)
    end

    custom_robot(
      'bravo-lthr-96-rt-to-lthr-96-pcr-1-and-2',
      name: 'bravo LTHR RT => LTHR PCR 1 and 2',
      beds: {
        bed(9).barcode => {
          purpose: ['LTHR RT', 'LTHR RT-S'],
          states: ['passed'],
          label: 'Bed 9'
        },
        bed(4).barcode => {
          purpose: 'LTHR PCR 1',
          states: ['pending'],
          label: 'Bed 4',
          target_state: 'passed',
          parent: bed(9).barcode
        },
        bed(6).barcode => {
          purpose: 'LTHR PCR 2',
          states: ['pending'],
          label: 'Bed 6',
          target_state: 'passed',
          parent: bed(9).barcode
        }
      }
    )

    custom_robot(
      'mosquito-lthr-96-pcr-1-and-2-to-lthr-96-lib-pcr-1-and-2',
      name: 'Mosquito LV LTHR PCR 1 and 2 => LTHR Lib PCR 1 and 2',
      beds: {
        bed(2).barcode => {
          purpose: 'LTHR PCR 1',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(4).barcode => {
          purpose: 'LTHR PCR 2',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(3).barcode => {
          purpose: 'LTHR Lib PCR 1',
          states: ['pending'],
          label: 'Bed 3',
          target_state: 'passed',
          parent: bed(2).barcode
        },
        bed(5).barcode => {
          purpose: 'LTHR Lib PCR 2',
          states: ['pending'],
          label: 'Bed 5',
          target_state: 'passed',
          parent: bed(4).barcode
        }
      }
    )

    custom_robot(
      'bravo-lthr-96-pcr-1-and-2-to-lthr-96-lib-pcr-pool',
      name: 'bravo LTHR Lib PCR 1 and 2 => Heron LTHR Lib PCR pool',
      beds: {
        bed(4).barcode => {
          purpose: 'LTHR Lib PCR 1',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(6).barcode => {
          purpose: 'LTHR Lib PCR 2',
          states: ['passed'],
          label: 'Bed 6'
        },
        bed(8).barcode => {
          purpose: 'LTHR Lib PCR pool',
          states: ['pending'],
          label: 'Bed 8',
          parents: [bed(4).barcode, bed(6).barcode],
          target_state: 'passed'
        }
      }
    )

    # Robots for pWGS 384 pipeline

    custom_robot(
      'star-lb-post-shear-to-pwgs-384-post-shear-xp',
      name: 'STAR LB Post Shear => pWGS-384 Post Shear XP',
      beds: {
        bed(12).barcode => {
          purpose: 'LB Post Shear',
          states: ['passed'],
          child: bed(7).barcode,
          label: 'Bed 12'
        },
        bed(13).barcode => {
          purpose: 'LB Post Shear',
          states: ['passed'],
          child: bed(7).barcode,
          label: 'Bed 13'
        },
        bed(14).barcode => {
          purpose: 'LB Post Shear',
          states: ['passed'],
          child: bed(7).barcode,
          label: 'Bed 14'
        },
        bed(15).barcode => {
          purpose: 'LB Post Shear',
          states: ['passed'],
          child: bed(7).barcode,
          label: 'Bed 15'
        },
        bed(7).barcode => {
          purpose: 'pWGS-384 Post Shear XP',
          states: ['pending'],
          label: 'Bed 7',
          parents: [bed(12).barcode, bed(13).barcode, bed(14).barcode, bed(15).barcode],
          target_state: 'passed'
        }
      },
      destination_bed: bed(7).barcode,
      class: 'Robots::QuadrantRobot'
    )

    custom_robot(
      'bravo-pwgs-384-post-shear-xp-to-pwgs-384-end-prep',
      name: 'Bravo pWGS-384 Post Shear XP => pWGS-384 End Prep',
      require_robot: true,
      beds: {
        bed(4).barcode => {
          purpose: 'pWGS-384 Post Shear XP',
          states: ['passed'],
          label: 'Bed 4'
        },
        car('1,4').barcode => {
          purpose: 'pWGS-384 End Prep',
          states: ['pending'],
          label: 'Carousel 1,4',
          target_state: 'started'
        },
        car('3,5').barcode => {
          purpose: 'pWGS-384 AL Lib',
          states: ['pending'],
          label: 'Carousel 3,5',
          target_state: 'started'
        }
      }
    )

    custom_robot(
      'bravo-pwgs-384-end-prep',
      name: 'Bravo pWGS-384 End Prep',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'pWGS-384 End Prep',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-pwgs-384-al-lib',
      name: 'Bravo pWGS-384 AL-Lib',
      verify_robot: true,
      beds: {
        bed(5).barcode => {
          purpose: 'pWGS-384 AL Lib',
          states: ['started'],
          label: 'Bed 5',
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-pwgs-384-al-lib-to-pwgs-384-lib-pcr',
      name: 'Bravo pWGS-384 AL Lib => pWGS-384 Lib PCR',
      verify_robot: true,
      beds: {
        bed(7).barcode => {
          purpose: 'pWGS-384 AL Lib',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(6).barcode => {
          purpose: 'pWGS-384 Lib PCR',
          states: ['pending'],
          label: 'Bed 6',
          parent: bed(7).barcode,
          target_state: 'passed'
        }
      }
    )

    # Robots for Combined LCM pipeline

    custom_robot(
      'bravo-clcm-stock-to-clcm-lysate-dna-and-rna',
      name: 'Bravo CLCM Stock => CLCM Lysate DNA and RNA',
      require_robot: true,
      beds: {
        bed(4).barcode => {
          purpose: 'CLCM Stock',
          states: ['passed'],
          label: 'Bed 4'
        },
        bed(7).barcode => {
          purpose: 'CLCM Stock',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(3).barcode => {
          purpose: 'CLCM Stock',
          states: ['passed'],
          label: 'Bed 3'
        },
        bed(6).barcode => {
          purpose: 'CLCM Stock',
          states: ['passed'],
          label: 'Bed 6'
        },
        bed(5).barcode => {
          purpose: 'CLCM Lysate RNA',
          states: ['pending'],
          label: 'Bed 5',
          target_state: 'passed'
        },
        bed(8).barcode => {
          purpose: 'CLCM Lysate DNA',
          states: ['pending'],
          label: 'Bed 8',
          target_state: 'passed'
        }
      },
      class: 'Robots::PoolingAndSplittingRobot',
      relationships: [
        {
          'type' => 'RNA and DNA split',
          'options' => {
            'parents' => [bed(4).barcode, bed(7).barcode, bed(3).barcode, bed(6).barcode],
            'children' => [bed(5).barcode, bed(8).barcode]
          }
        }
      ]
    )

    custom_robot(
      'bravo-clcm-dna-end-prep-to-clcm-dna-lib-pcr',
      name: 'Bravo CLCM DNA End Prep => CLCM DNA Lib PCR',
      require_robot: true,
      beds: {
        bed(7).barcode => {
          purpose: 'CLCM DNA End Prep',
          states: ['passed'],
          label: 'Bed 7',
          child: bed(6).barcode
        },
        bed(6).barcode => {
          purpose: 'CLCM DNA Lib PCR',
          states: ['pending'],
          label: 'Bed 6',
          parent: bed(7).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'bravo-clcm-rna-end-prep-to-clcm-rna-lib-pcr',
      name: 'Bravo CLCM RNA End Prep => CLCM RNA Lib PCR',
      require_robot: true,
      beds: {
        bed(7).barcode => {
          purpose: 'CLCM RNA End Prep',
          states: ['passed'],
          label: 'Bed 7',
          child: bed(6).barcode
        },
        bed(6).barcode => {
          purpose: 'CLCM RNA Lib PCR',
          states: ['pending'],
          label: 'Bed 6',
          parent: bed(7).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'star-96-clcm-dna-lib-pcr-purification',
      name: 'STAR-96 CLCM DNA Lib PCR => CLCM DNA Lib PCR XP',
      verify_robot: false,
      beds: {
        bed(7).barcode => {
          purpose: 'CLCM DNA Lib PCR',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(9).barcode => {
          purpose: 'CLCM DNA Lib PCR XP',
          states: ['pending'],
          label: 'Bed 9',
          parent: bed(7).barcode,
          target_state: 'passed'
        },
        bed(12).barcode => {
          purpose: 'CLCM DNA Lib PCR',
          states: ['passed'],
          label: 'Bed 12'
        },
        bed(14).barcode => {
          purpose: 'CLCM DNA Lib PCR XP',
          states: ['pending'],
          label: 'Bed 14',
          parent: bed(12).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'zephyr-clcm-dna-lib-pcr-purification',
      name: 'Zephyr CLCM DNA Lib PCR => CLCM DNA Lib PCR XP',
      verify_robot: false,
      beds: {
        bed(2).barcode => {
          purpose: 'CLCM DNA Lib PCR',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(7).barcode => {
          purpose: 'CLCM DNA Lib PCR XP',
          states: ['pending'],
          label: 'Bed 7',
          parent: bed(2).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'star-96-clcm-rna-lib-pcr-purification',
      name: 'STAR-96 CLCM RNA Lib PCR => CLCM RNA Lib PCR XP',
      verify_robot: false,
      beds: {
        bed(7).barcode => {
          purpose: 'CLCM RNA Lib PCR',
          states: ['passed'],
          label: 'Bed 7'
        },
        bed(9).barcode => {
          purpose: 'CLCM RNA Lib PCR XP',
          states: ['pending'],
          label: 'Bed 9',
          parent: bed(7).barcode,
          target_state: 'passed'
        },
        bed(12).barcode => {
          purpose: 'CLCM RNA Lib PCR',
          states: ['passed'],
          label: 'Bed 12'
        },
        bed(14).barcode => {
          purpose: 'CLCM RNA Lib PCR XP',
          states: ['pending'],
          label: 'Bed 14',
          parent: bed(12).barcode,
          target_state: 'passed'
        }
      }
    )

    custom_robot(
      'zephyr-clcm-rna-lib-pcr-purification',
      name: 'Zephyr CLCM RNA Lib PCR => CLCM RNA Lib PCR XP',
      verify_robot: false,
      beds: {
        bed(2).barcode => {
          purpose: 'CLCM RNA Lib PCR',
          states: ['passed'],
          label: 'Bed 2'
        },
        bed(7).barcode => {
          purpose: 'CLCM RNA Lib PCR XP',
          states: ['pending'],
          label: 'Bed 7',
          parent: bed(2).barcode,
          target_state: 'passed'
        }
      }
    )

    # Bioscan Beckman bed verification
    # LILYS-96 Stock ethanol removal step
    custom_robot(
      'beckman-lilys-96-stock-preparation',
      name: 'Beckman LILYS-96 Stock Preparation',
      require_robot: true,
      beds: {
        bed(9).barcode => {
          purpose: 'LILYS-96 Stock',
          states: ['passed'],
          label: 'Bed 9',
          target_state: 'passed'
        }
      }
    )

    # Bioscan Beckman bed verification
    # LILYS-96 Stock to LBSN-96 Lysate
    # one to one stamp with added randomised controls
    custom_robot(
      'beckman-lilys-96-stock-to-lbsn-96-lysate',
      name: 'Beckman LILYS-96 Stock => LBSN-96 Lysate',
      verify_robot: true,
      beds: {
        bed(9).barcode => {
          purpose: 'LILYS-96 Stock',
          states: ['passed'],
          label: 'Bed 9',
          target_state: 'passed'
        },
        bed(14).barcode => {
          purpose: 'LBSN-96 Lysate',
          states: ['pending'],
          label: 'Bed 14',
          target_state: 'passed',
          parent: bed(9).barcode
        }
      }
    )

    # Bioscan Mosquito bed verification
    # LBSN-96 Lysate plates to LBSN-384 PCR 1
    # transfers up to 4 plates into the 384 destination
    custom_robot(
      'mosquito-lbsn-96-lysate-to-lbsn-384-pcr-1',
      name: 'Mosquito LBSN-96 Lysate => LBSN-384 PCR 1',
      require_robot: true,
      beds: {
        bed(1).barcode => {
          purpose: 'LBSN-96 Lysate',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 1'
        },
        bed(2).barcode => {
          purpose: 'LBSN-96 Lysate',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 2'
        },
        bed(3).barcode => {
          purpose: 'LBSN-96 Lysate',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 3'
        },
        bed(4).barcode => {
          purpose: 'LBSN-96 Lysate',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 4'
        },
        bed(5).barcode => {
          purpose: 'LBSN-384 PCR 1',
          states: ['pending'],
          label: 'Bed 5',
          parents: [bed(1).barcode, bed(2).barcode, bed(3).barcode, bed(4).barcode],
          target_state: 'passed'
        }
      },
      destination_bed: bed(5).barcode,
      class: 'Robots::QuadrantRobot'
    )

    # Bioscan Mosquito bed verification
    # LBSN-384 PCR 1 to LBSN-384 PCR 2
    # transfers up to 2 pairs of plates at a time
    custom_robot(
      'mosquito-lbsn-384-pcr-1-to-lbsn-384-pcr-2',
      name: 'Mosquito LBSN-384 PCR 1 => LBSN-384 PCR 2',
      require_robot: true,
      beds: {
        bed(2).barcode => {
          purpose: 'LBSN-384 PCR 1',
          states: ['passed'],
          child: bed(3).barcode,
          label: 'Bed 2'
        },
        bed(3).barcode => {
          purpose: 'LBSN-384 PCR 2',
          states: ['pending'],
          label: 'Bed 3',
          parent: bed(2).barcode,
          target_state: 'passed'
        },
        bed(4).barcode => {
          purpose: 'LBSN-384 PCR 1',
          states: ['passed'],
          child: bed(5).barcode,
          label: 'Bed 4'
        },
        bed(5).barcode => {
          purpose: 'LBSN-384 PCR 2',
          states: ['pending'],
          label: 'Bed 5',
          parent: bed(4).barcode,
          target_state: 'passed'
        }
      }
    )

    # hamilton robot for stamping deep well stock plates to shallow well stock plates
    custom_robot(
      'hamilton-ldw-96-stock-to-lsw-96-stock',
      name: 'Hamilton LDW-96 Stock => LSW-96 Stock',
      beds: {
        bed(12).barcode => {
          purpose: 'LDW-96 Stock',
          states: ['passed'],
          label: 'Bed 12'
        },
        bed(2).barcode => {
          purpose: 'LSW-96 Stock',
          states: ['pending'],
          label: 'Bed 2',
          parent: bed(12).barcode,
          target_state: 'passed'
        }
      }
    )
  end
