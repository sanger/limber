ROBOT_CONFIG = {
  'fx' => {
    :name => 'fx',
    :layout => 'cytomat',
    :beds   => {
      '1' => {:order=>1, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate A'},
      '2' => {:order=>2, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate A', :parent =>'1', :target_state => 'started'},
      '3' => {:order=>3, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate B'},
      '4' => {:order=>4, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate B', :parent =>'3', :target_state => 'started'},
      '5' => {:order=>5, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate C'},
      '6' => {:order=>6, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate C', :parent =>'5', :target_state => 'started'},
      '7' => {:order=>7, :purpose => 'Post Shear', :states => ['qc_complete'], :label => 'Post Shear Plate D'},
      '8' => {:order=>8, :purpose => 'AL Libs',    :states => ['pending'],     :label => 'AL Libs Plate D', :parent =>'7', :target_state => 'started'}
    }
  },
  'fx-add-tags' => {
    :name => 'fx-add-tags',
    :layout => 'bed',
    :beds   => {
      '5800000018068' => {:purpose => 'AL Libs', :states => ['started']},
      '5800000058422' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000018068', :target_state => 'fx_started'},
      '5800000028104' => {:purpose => 'AL Libs', :states => ['started']},
      '5800000068568' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000028104', :target_state => 'fx_started'},
      '5800000038240' => {:purpose => 'AL Libs', :states => ['started']},
      '5800000078604' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000038240', :target_state => 'fx_started'},
      '5800000048386' => {:purpose => 'AL Libs', :states => ['started']},
      '5800000088740' => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>'5800000048386', :target_state => 'fx_started'}
    }
  },
  'nx-8' => {
    :name => 'nx-8',
    :layout => 'cytomat',
    :beds   => {
      '1'  => {:order=>1, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate A'},
      '2'  => {:order=>2, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate A', :parent =>'1', :target_state => 'started'},
      '3'  => {:order=>3, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate B'},
      '4'  => {:order=>4, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate B', :parent =>'3', :target_state => 'started'},
      '5'  => {:order=>5, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate C'},
      '6'  => {:order=>6, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate C', :parent =>'5', :target_state => 'started'},
      '7'  => {:order=>7, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate D'},
      '8'  => {:order=>8, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate D', :parent =>'7', :target_state => 'started'}
    }
  }
}
