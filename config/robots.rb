ROBOT_CONFIG = {
  'fx' => {
    :name => 'fx',
    :layout => 'cytomat',
    :beds   => {
      '1'  => {:order=>1, :purpose => 'Post Shear', :state => 'qc_complete', :label => 'QC Plate A'},
      '2'  => {:order=>2, :purpose => 'AL Libs',    :state => 'pending',     :label => 'AL Libs Plate A', :parent =>'1'},
      '3'  => {:order=>3, :purpose => 'Lib PCR',    :state => 'pending',     :label => 'Lib PCR Plate A', :parent =>'2', :target_state => 'fx_started'},
      '4'  => {:order=>4, :purpose => 'Post Shear', :state => 'qc_complete', :label => 'QC Plate B'},
      '5'  => {:order=>5, :purpose => 'AL Libs',    :state => 'pending',     :label => 'AL Libs Plate B', :parent =>'4'},
      '6'  => {:order=>6, :purpose => 'Lib PCR',    :state => 'pending',     :label => 'Lib PCR Plate B', :parent =>'5', :target_state => 'fx_started'},
      '7'  => {:order=>7, :purpose => 'Post Shear', :state => 'qc_complete', :label => 'QC Plate C'},
      '8'  => {:order=>8, :purpose => 'AL Libs',    :state => 'pending',     :label => 'AL Libs Plate C', :parent =>'7'},
      '9'  => {:order=>9, :purpose => 'Lib PCR',    :state => 'pending',     :label => 'Lib PCR Plate C', :parent =>'8', :target_state => 'fx_started'},
      '10' => {:order=>10, :purpose => 'Post Shear', :state => 'qc_complete', :label => 'QC Plate D'},
      '11' => {:order=>11, :purpose => 'AL Libs',    :state => 'pending',     :label => 'AL Libs Plate D', :parent =>'10'},
      '12' => {:order=>12, :purpose => 'Lib PCR',    :state => 'pending',     :label => 'Lib PCR Plate D', :parent =>'11', :target_state => 'fx_started'},
    }
  }
}
