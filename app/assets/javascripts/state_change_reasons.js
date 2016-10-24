// Global SCAPE.message method
(function($, window, undefined){
  "use strict";

  var displayReason = function() {
    var new_state = this.value;
    if($('.reason:visible').length === 0) {
      $('#'+new_state+'_reasons').slideDown('slow').find('select:disabled').prop('disabled',false);
    }
    else {
      $('.reason').not('#'+new_state+'_reasons').slideUp('slow', function(){
        $('#'+new_state+'_reasons').slideDown('slow').find('select:disabled').prop('disabled',false);
      }).prop('disabled',true);
    }
  };

  $(document).ready(function(){
    $('#state-changer').find('#state').on('change', displayReason);
  });



})(jQuery,window);
