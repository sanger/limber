// Global SCAPE.message method
(function($, window, undefined){
  "use strict";

  var updateDisplay = function(new_state, speed) {
    if ($('.reason:visible').length === 0) {
      $('#' + new_state + '_reasons').slideDown(speed).find('select:disabled').prop('disabled', false);
    }
    else {
      $('.reason').not('#' + new_state + '_reasons').slideUp(speed, function () {
        $('#' + new_state + '_reasons').slideDown(speed).find('select:disabled').prop('disabled', false);
      }).prop('disabled', true);
    }
  }

  var displayReason = function() {
    updateDisplay(this.value, 'fast')
  };

  $(function(){
    $('#state-changer').find('input[type=radio]').on('change', displayReason);
  });
})(jQuery,window);
