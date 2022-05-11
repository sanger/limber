;(function ($, window, undefined) {
  'use strict'

  var updateDisplay = function (new_state, speed) {
    $('.reason')
      .not('#' + new_state + '_reasons')
      .slideUp(speed)
    $('#' + new_state + '_reasons').slideDown(speed)
  }

  var displayReason = function () {
    updateDisplay(this.value, 'fast')
  }

  $(function () {
    $('#state-changer').find('input[type=radio]').on('change', displayReason)
  })
})(jQuery, window)
