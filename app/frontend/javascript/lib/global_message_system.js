import $ from 'jquery'

// Global SCAPE.message method

let SCAPE = {}

SCAPE.message = function (message, status) {
  if (message == '') {
    $('#validation_report').empty()
    return
  }

  $('#validation_report')
    .empty()
    .append(
      $(document.createElement('div'))
        .addClass('alert')
        .addClass('alert-' + status)
        .text(message),
    )
}

export default SCAPE
