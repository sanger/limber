ROBOT_CONFIG = {
  'illumina_b' => {
    'fx' => {
      :name => 'Illumina B fx',
      :layout => 'bed',
      :beds   => {
        '5800000018068' => {:order=>1, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate A'},
        '5800000028104' => {:order=>2, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate A', :parent =>'5800000018068', :target_state => 'started'},
        '5800000038240' => {:order=>3, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate B'},
        '5800000048386' => {:order=>4, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate B', :parent =>'5800000038240', :target_state => 'started'},
        '5800000058422' => {:order=>5, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate C'},
        '5800000068568' => {:order=>6, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate C', :parent =>'5800000058422', :target_state => 'started'},
        '5800000078604' => {:order=>7, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate D'},
        '5800000088740' => {:order=>8, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate D', :parent =>'5800000078604', :target_state => 'started'}
      }
    },
    'fx-add-tags' => {
      :name => 'Illumina B fx-add-tags',
      :layout => 'bed',
      :beds   => {
        '5800000018068' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000058422' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000018068', :target_state => 'started_fx'},
        '5800000028104' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000068568' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000028104', :target_state => 'started_fx'},
        '5800000038240' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000078604' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000038240', :target_state => 'started_fx'},
        '5800000048386' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000088740' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000048386', :target_state => 'started_fx'}
      }
    },
    'nx-96' => {
      :name => 'Illumina B nx-96',
      :layout => 'bed',
      :beds   => {
        '5800000018068'  => {:order=>1, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate A'},
        '5800000028104'  => {:order=>2, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate A', :parent =>'5800000018068', :target_state => 'started'},
        '5800000038240'  => {:order=>3, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate B'},
        '5800000048386'  => {:order=>4, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate B', :parent =>'5800000038240', :target_state => 'started'},
        '5800000058422'  => {:order=>5, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate C'},
        '5800000068568'  => {:order=>6, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate C', :parent =>'5800000058422', :target_state => 'started'},
        '5800000078604'  => {:order=>7, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate D'},
        '5800000088740'  => {:order=>8, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate D', :parent =>'5800000078604', :target_state => 'started'}
      }
    }
  },
  'illumina_a' => {
    'fx' => {
      :name => 'Illumina A fx',
      :layout => 'bed',
      :beds   => {
        '5800000018068' => {:order=>1, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate A'},
        '5800000028104' => {:order=>2, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate A', :parent =>'5800000018068', :target_state => 'started'},
        '5800000038240' => {:order=>3, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate B'},
        '5800000048386' => {:order=>4, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate B', :parent =>'5800000038240', :target_state => 'started'},
        '5800000058422' => {:order=>5, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate C'},
        '5800000068568' => {:order=>6, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate C', :parent =>'5800000058422', :target_state => 'started'},
        '5800000078604' => {:order=>7, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate D'},
        '5800000088740' => {:order=>8, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate D', :parent =>'5800000078604', :target_state => 'started'}
      }
    },
    'fx-add-tags' => {
      :name => 'Illumina A fx-add-tags',
      :layout => 'bed',
      :beds   => {
        '5800000018068' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000058422' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000018068', :target_state => 'started_fx'},
        '5800000028104' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000068568' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000028104', :target_state => 'started_fx'},
        '5800000038240' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000078604' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000038240', :target_state => 'started_fx'},
        '5800000048386' => {:purpose => 'AL Libs', :states => ['started']},
        '5800000088740' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000048386', :target_state => 'started_fx'}
      }
    },
    'nx-96' => {
      :name => 'Illumina A nx-96',
      :layout => 'bed',
      :beds   => {
        '5800000018068'  => {:order=>1, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate A'},
        '5800000028104'  => {:order=>2, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate A', :parent =>'5800000018068', :target_state => 'started'},
        '5800000038240'  => {:order=>3, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate B'},
        '5800000048386'  => {:order=>4, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate B', :parent =>'5800000038240', :target_state => 'started'},
        '5800000058422'  => {:order=>5, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate C'},
        '5800000068568'  => {:order=>6, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate C', :parent =>'5800000058422', :target_state => 'started'},
        '5800000078604'  => {:order=>7, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate D'},
        '5800000088740'  => {:order=>8, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate D', :parent =>'5800000078604', :target_state => 'started'}
      }
    }
  }
}

LOCATION_PIPELINES = {
  'Library creation freezer' =>'illumina_b',
  'Pulldown freezer'         =>'illumina_a'
}
