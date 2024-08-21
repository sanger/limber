import $ from 'jquery'

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
