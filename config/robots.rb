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

  custom_robot('zephyr-lib-pcr-purification',
               name: 'Zephyr LB Lib PCR => LB Lib PCR XP',
               layout: 'bed',
               verify_robot: false,
               beds: {
                 bed(2).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 2' },
                 bed(7).barcode  => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 7', parent: bed(2).barcode, target_state: 'passed' }
               })

  custom_robot('nx-8-lib-pcr-xp-to-isch-lib-pool',
               name: 'nx-8 Lib PCR-XP => LB Lib PrePool',
               layout: 'bed',
               beds: {
                 bed(2).barcode => { purpose: 'LB Lib PCR-XP', states: %w[passed qc_complete], child: bed(4).barcode, label: 'Bed 2' },
                 bed(5).barcode => { purpose: 'LB Lib PCR-XP', states: %w[passed qc_complete], child: bed(4).barcode, label: 'Bed 5' },
                 bed(3).barcode => { purpose: 'LB Lib PCR-XP', states: %w[passed qc_complete], child: bed(4).barcode, label: 'Bed 3' },
                 bed(6).barcode => { purpose: 'LB Lib PCR-XP', states: %w[passed qc_complete], child: bed(4).barcode, label: 'Bed 6' },
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
    layout: 'bed',
    beds: {
      bed(1).barcode => { purpose: 'PF Post Shear', states: ['passed'], label: 'Bed 1' },
      bed(9).barcode   => { purpose: 'PF Post Shear XP', states: ['pending'], label: 'Bed 9', parent: bed(1).barcode, target_state: 'started' },
      bed(2).barcode   => { purpose: 'PF Post Shear',    states: ['passed'],  label: 'Bed 2' },
      bed(10).barcode  => { purpose: 'PF Post Shear XP', states: ['pending'], label: 'Bed 10', parent: bed(2).barcode, target_state: 'started' },
      bed(3).barcode   => { purpose: 'PF Post Shear',    states: ['passed'],  label: 'Bed 3' },
      bed(11).barcode  => { purpose: 'PF Post Shear XP', states: ['pending'], label: 'Bed 11', parent: bed(3).barcode, target_state: 'started' },
      bed(4).barcode   => { purpose: 'PF Post Shear',    states: ['passed'],  label: 'Bed 4' },
      bed(12).barcode  => { purpose: 'PF Post Shear XP', states: ['pending'], label: 'Bed 12', parent: bed(4).barcode, target_state: 'started' }
    }
  )

  custom_robot(
    'nx-96-scrna-stock-to-scrna-cdna-xp',
    name: 'nx-96 scRNA Stock => scRNA cDNA-XP',
    layout: 'bed',
    beds: {
      bed(1).barcode => { purpose: 'scRNA Stock', states: ['passed'], label: 'Bed 1' },
      bed(9).barcode   => { purpose: 'scRNA cDNA-XP', states: ['pending'], label: 'Bed 9', parent: bed(1).barcode, target_state: 'passed' },
      bed(2).barcode   => { purpose: 'scRNA Stock', states: ['passed'], label: 'Bed 2' },
      bed(10).barcode  => { purpose: 'scRNA cDNA-XP', states: ['pending'], label: 'Bed 10', parent: bed(2).barcode, target_state: 'passed' },
      bed(3).barcode   => { purpose: 'scRNA Stock', states: ['passed'], label: 'Bed 3' },
      bed(11).barcode  => { purpose: 'scRNA cDNA-XP', states: ['pending'], label: 'Bed 11', parent: bed(3).barcode, target_state: 'passed' },
      bed(4).barcode   => { purpose: 'scRNA Stock', states: ['passed'], label: 'Bed 4' },
      bed(12).barcode  => { purpose: 'scRNA cDNA-XP', states: ['pending'], label: 'Bed 12', parent: bed(4).barcode, target_state: 'passed' }
    }
  )

  custom_robot(
    'star-384-scrna-384-stock-to-scrna-384-cdna-xp',
    name: 'STAR-384 scRNA Stock => scRNA-384 cDNA-XP',
    layout: 'bed',
    beds: {
      bed(12).barcode => { purpose: 'scRNA-384 Stock', states: ['passed'], label: 'Bed 12' },
      bed(17).barcode => { purpose: 'scRNA-384 cDNA-XP', states: ['pending'], label: 'Bed 17', parent: bed(12).barcode, target_state: 'passed' },
      bed(13).barcode => { purpose: 'scRNA-384 Stock', states: ['passed'], label: 'Bed 13' },
      bed(18).barcode => { purpose: 'scRNA-384 cDNA-XP', states: ['pending'], label: 'Bed 18', parent: bed(13).barcode, target_state: 'passed' },
      bed(14).barcode => { purpose: 'scRNA-384 Stock', states: ['passed'], label: 'Bed 14' },
      bed(19).barcode => { purpose: 'scRNA-384 cDNA-XP', states: ['pending'], label: 'Bed 19', parent: bed(14).barcode, target_state: 'passed' },
      bed(15).barcode => { purpose: 'scRNA-384 Stock', states: ['passed'], label: 'Bed 15' },
      bed(20).barcode => { purpose: 'scRNA-384 cDNA-XP', states: ['pending'], label: 'Bed 20', parent: bed(15).barcode, target_state: 'passed' }
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
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(5).barcode => { purpose: 'scRNA End Prep', states: ['started'], label: 'Bed 5', target_state: 'passed' }
               })

  custom_robot('bravo-scdna-384-end-prep',
               name: 'bravo scDNA-384 End Prep',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(5).barcode => { purpose: 'scRNA-384 End Prep', states: ['started'], label: 'Bed 5', target_state: 'passed' }
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
    layout: 'bed',
    beds: {
      bed(4).barcode => { purpose: 'PF Post Shear', states: ['passed'], label: 'Bed 4' },
      car('1,4').barcode => { purpose: 'PF End Prep', states: ['pending'], label: 'Carousel 1,4', parent: bed(4).barcode, target_state: 'started' }
    }
  )

  custom_robot(
    'bravo-pf-end-prep',
    name: 'Bravo PF End Preparation',
    layout: 'bed',
    beds: {
      bed(5).barcode => { purpose: 'PF End Prep', states: ['started'], label: 'Bed 5', target_state: 'passed' }
    }
  )

  custom_robot(
    'bravo-pf-post-shear-xp-prep',
    name: 'Bravo PF Post Shear XP Preparation',
    layout: 'bed',
    beds: {
      bed(5).barcode => { purpose: 'PF Post Shear XP', states: ['started'], label: 'Bed 5', target_state: 'passed' }
    }
  )

  custom_robot(
    'bravo-pf-post-shear-xp-to-pf-lib-xp',
    name: 'Bravo PF Post Shear XP to PF Lib XP',
    layout: 'bed',
    beds: {
      car('1,3').barcode => { purpose: 'PF Post Shear XP', states: ['passed'], label: 'Carousel 1,3' },
      bed(6).barcode => { purpose: 'PF Lib', states: ['pending'], label: 'Bed 6', target_state: 'passed', parent: car('1,3').barcode },
      car('4,3').barcode => { purpose: 'PF Lib XP', states: ['pending'], label: 'Carousel 4,3', target_state: 'passed', parent: bed(6).barcode }
    }
  )

  custom_robot(
    'bravo-pf-end-prep-to-pf-lib-xp-2',
    name: 'Bravo PF End Prep to PF Lib XP2',
    layout: 'bed',
    beds: {
      bed(5).barcode => { purpose: 'PF End Prep', states: ['passed'], label: 'Bed 5' },
      bed(6).barcode => { purpose: 'PF Lib', states: ['pending'], label: 'Bed 6', target_state: 'passed', parent: bed(5).barcode },
      car('4,3').barcode => { purpose: 'PF Lib XP2', states: ['pending'], label: 'Carousel 4,3', target_state: 'passed', parent: bed(6).barcode }
    }
  )

  custom_robot(
    'bravo-mrna-capture-rnaag',
    name: 'Bravo mRNA capture RNAAG',
    layout: 'bed',
    beds: {
      bed(7).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 7' },
      bed(6).barcode => { purpose: 'LBR mRNA Cap', states: ['pending'], label: 'Bed 6', target_state: 'started', parent: bed(7).barcode },
      car('2,3').barcode => { purpose: 'LBR Globin', states: ['pending'], label: 'Carousel 2,3', parent: bed(6).barcode }
    }
  )

  custom_robot(
    'bravo-mrna-capture-rnaa',
    name: 'Bravo mRNA capture RNAA',
    layout: 'bed',
    beds: {
      bed(7).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 7' },
      bed(6).barcode => { purpose: 'LBR mRNA Cap', states: ['pending'], label: 'Bed 6', target_state: 'started', parent: bed(7).barcode },
      car('2,3').barcode => { purpose: 'LBR Frag', states: ['pending'], label: 'Carousel 2,3', parent: bed(6).barcode },
      car('3,4').barcode => { purpose: 'LB cDNA', states: ['pending'], label: 'Carousel 3,4', parent: car('2,3').barcode },
      car('4,3').barcode => { purpose: 'LB cDNA XP', states: ['pending'], label: 'Carousel 4,3', parent: car('3,4').barcode }
    }
  )

  custom_robot(
    'bravo-mrna-capture-rnaa-m',
    name: 'Bravo mRNA capture RNAA (modular)',
    layout: 'bed',
    beds: {
      bed(7).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 7' },
      bed(6).barcode => { purpose: 'LBR mRNA Cap', states: ['pending'], label: 'Bed 6', target_state: 'started', parent: bed(7).barcode },
      car('2,3').barcode => { purpose: 'LBR Frag', states: ['pending'], label: 'Carousel 2,3', parent: bed(6).barcode }
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
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR mRNA Cap', states: ['started'], label: 'Bed 8', target_state: 'passed' }
               })

  custom_robot('bravo-lbr-mrna-cap-globin',
               name: 'Bravo LBR mRNA Cap to LBR Globin',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR mRNA Cap', states: ['passed'], label: 'Bed 8' },
                 car('2,3').barcode => { purpose: 'LBR Globin', states: ['pending'], label: 'Carousel 2,3', parent: bed(8).barcode, target_state: 'processed_1' }
               })

  custom_robot(
    'bravo-hyb-setup',
    name: 'Bravo Hyb Setup',
    layout: 'bed',
    beds: {
      bed(6).barcode => { purpose: 'LBR Globin', states: ['processed_1'], label: 'Bed 6', target_state: 'processed_2' },
      car('4,3').barcode => { purpose: 'LBR Globin DNase', states: ['pending'], label: 'Carousel 4,3', parent: bed(6).barcode },
      car('4,4').barcode => { purpose: 'LBR Frag cDNA', states: ['pending'], label: 'Carousel 4,4', parent: car('4,3').barcode }
    }
  )

  custom_robot(
    'bravo-ribo-hyb-setup',
    name: 'Bravo Ribo Hyb Setup',
    layout: 'bed',
    beds: {
      bed(6).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 6' },
      car('4,3').barcode => { purpose: 'LBR Ribo DNase', states: ['pending'], label: 'Carousel 4,3', parent: bed(6).barcode },
      car('4,4').barcode => { purpose: 'LBR Frag cDNA', states: ['pending'], label: 'Carousel 4,4', parent: car('4,3').barcode }
    }
  )

  custom_robot(
    'bravo-riboglobin-hyb-setup',
    name: 'Bravo Ribo Globin Hyb Setup',
    layout: 'bed',
    beds: {
      bed(6).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 6' },
      car('4,3').barcode => { purpose: 'LBR RiboGlobin DNase', states: ['pending'], label: 'Carousel 4,3', parent: bed(6).barcode },
      car('4,4').barcode => { purpose: 'LBR Frag cDNA', states: ['pending'], label: 'Carousel 4,4', parent: car('4,3').barcode }
    }
  )

  custom_robot('bravo-depletion-setup',
               name: 'Bravo Depletion Setup',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(6).barcode => { purpose: 'LBR Globin', states: ['processed_2'], label: 'Bed 6', target_state: 'passed' }
               })

  custom_robot('bravo-ribo-depletion-setup',
               name: 'Bravo Ribo Depletion Setup',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(6).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 6' }
               })

  custom_robot('bravo-riboglobin-depletion-setup',
               name: 'Bravo Ribo Globin Depletion Setup',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(6).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 6' }
               })

  custom_robot('bravo-globin-globin-dnase',
               name: 'Bravo Globin To Globin DNase',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Globin', states: ['passed'], label: 'Bed 8' },
                 car('4,3').barcode => { purpose: 'LBR Globin DNase', states: ['pending'], label: 'Carousel 4,3', parent: bed(8).barcode, target_state: 'passed' }
               })

  custom_robot('bravo-ribo-dnase',
               name: 'Bravo Cherrypick To Ribo DNase',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 8' },
                 car('4,3').barcode => { purpose: 'LBR Ribo DNase', states: ['pending'], label: 'Carousel 4,3', parent: bed(8).barcode, target_state: 'passed' }
               })

  custom_robot('bravo-riboglobin-dnase',
               name: 'Bravo Cherrypick To Ribo Globin DNase',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Cherrypick', states: ['passed'], label: 'Bed 8' },
                 car('4,3').barcode => { purpose: 'LBR RiboGlobin DNase', states: ['pending'], label: 'Carousel 4,3', parent: bed(8).barcode, target_state: 'passed' }
               })

  custom_robot('bravo-lbr-globin-dnase-frag-cdna',
               name: 'Bravo LBR Globin DNase To LBR Frag cDNA',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Globin DNase', states: ['passed'], label: 'Bed 8' },
                 car('4,4').barcode => { purpose: 'LBR Frag cDNA', states: ['pending'], label: 'Carousel 4,4', parent: bed(8).barcode, target_state: 'processed_1' }
               })

  custom_robot('bravo-lbr-ribo-dnase-frag-cdna',
               name: 'Bravo LBR Ribo DNase To LBR Frag cDNA',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Ribo DNase', states: ['passed'], label: 'Bed 8' },
                 car('4,4').barcode => { purpose: 'LBR Frag cDNA', states: ['pending'], label: 'Carousel 4,4', parent: bed(8).barcode, target_state: 'processed_1' }
               })

  custom_robot('bravo-lbr-riboglobin-dnase-frag-cdna',
               name: 'Bravo LBR Ribo Globin DNase To LBR Frag cDNA',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR RiboGlobin DNase', states: ['passed'], label: 'Bed 8' },
                 car('4,4').barcode => { purpose: 'LBR Frag cDNA', states: ['pending'], label: 'Carousel 4,4', parent: bed(8).barcode, target_state: 'processed_1' }
               })

  custom_robot('bravo-strand-setup',
               name: 'Bravo Strand Setup',
               layout: 'bed',
               beds: {
                 bed(8).barcode => { purpose: 'LBR Frag cDNA', states: ['processed_1'], label: 'Bed 8', target_state: 'processed_2' },
                 car('4,3').barcode => { purpose: 'LB cDNA XP', states: ['pending'], label: 'Carousel 4,3', parent: bed(8).barcode }
               })

  custom_robot('bravo-strand-setup-rnaa-m',
               name: 'Bravo Strand Setup RNAA (modular)',
               layout: 'bed',
               beds: {
                 bed(8).barcode => { purpose: 'LBR Frag cDNA', states: ['passed'], label: 'Bed 8' },
                 car('3,4').barcode => { purpose: 'LB cDNA', states: ['pending'], label: 'Carousel 3,4', parent: bed(8).barcode },
                 car('4,3').barcode => { purpose: 'LB cDNA XP', states: ['pending'], label: 'Carousel 4,3', parent: car('3,4').barcode }
               })

  custom_robot('bravo-second-strand-setup',
               name: 'Bravo Second Strand Setup',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Frag cDNA', states: ['processed_2'], label: 'Bed 8', target_state: 'passed' }
               })

  custom_robot('bravo-lbr-frag-lb-cdna-xp',
               name: 'Bravo LBR Frag To LB cDNA XP',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LBR Frag cDNA', states: ['passed'], label: 'Bed 8' },
                 car('4,3').barcode => { purpose: 'LB cDNA XP', states: ['pending'], label: 'Carousel 4,3', parent: bed(8).barcode, target_state: 'passed' }
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
               layout: 'bed',
               verify_robot: true,
               beds: {
                 bed(8).barcode => { purpose: 'LB cDNA', states: ['started'], label: 'Bed 8', target_state: 'passed' }
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
    layout: 'bed',
    beds: {
      bed(1).barcode => { purpose: 'GBS PCR1', states: ['passed'], label: 'Bed 1' },
      bed(2).barcode => { purpose: 'GBS PCR2', states: ['pending'], label: 'Bed 2', parent: bed(1).barcode, target_state: 'started' },
      bed(4).barcode => { purpose: 'GBS PCR1', states: ['passed'], label: 'Bed 4' },
      bed(5).barcode => { purpose: 'GBS PCR2', states: ['pending'], label: 'Bed 5', parent: bed(4).barcode, target_state: 'started' }
    }
  )
end
