import jQuery from 'jquery'
;(function ($, _exports, undefined) {
  'use strict'

  let updateDisplay = function (new_state, speed) {
    $('.reason')
      .not('#' + new_state + '_reasons')
      .slideUp(speed)
    $('#' + new_state + '_reasons').slideDown(speed)
  }

  let displayReason = function () {
    updateDisplay(this.value, 'fast')
  }

  $(function () {
    $('#state-changer').find('input[type=radio]').on('change', displayReason)
  })
})(jQuery, window)
