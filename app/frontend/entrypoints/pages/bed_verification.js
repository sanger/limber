import $ from 'jquery'
import SCAPE from '@/javascript/lib/global_message_system.js'

// Bed Robot Page

//= require lib/ajax_support

let closeIcon = function () {
  return $(document.createElement('a'))
    .attr('class', 'btn-close float-end')
    .attr('aria-label', 'Close')
    .append($(document.createElement('span')).attr('aria-hidden', 'true'))
}

SCAPE.robot_beds = {}
SCAPE.robot_barcode = ''

let newScanned = function (bed, labware) {
  let new_li
  // $('#whole\\['+bed+'\\]').detach();
  new_li = $(document.createElement('li'))
    .attr('data-bed', bed)
    .attr('data-labware', labware)
    .attr('class', 'list-group-item list-group-item-action')
    .on('click', removeEntry)
    .append(
      $(document.createElement('a'))
        .attr('href', '#')
        .attr('class', 'list-group-item-action')
        .append(
          $(document.createElement('h3'))
            .attr('class', 'ui-li-heading')
            .text('Bed: ' + bed),
        )
        .append(closeIcon())
        .append(
          $(document.createElement('p'))
            .attr('class', 'ui-li-desc')
            .text('Labware: ' + labware),
        )
        .append(
          $(document.createElement('input'))
            .attr('type', 'hidden')
            .attr('id', 'bed_labwares[' + bed + ']')
            .attr('name', 'bed_labwares[' + bed + '][]')
            .val(labware),
        ),
    )
  SCAPE.robot_beds[bed] = SCAPE.robot_beds[bed] || []
  SCAPE.robot_beds[bed].push(labware)
  $('#start-robot').prop('disabled', true)
  $('#bed_list').append(new_li)
}

let newRobotScanned = function (robot_barcode) {
  $('#robot').text('Robot: ' + robot_barcode)
  $('#robot_barcode').val(robot_barcode)
  SCAPE.robot_barcode = robot_barcode
}

const removeEntry = function () {
  let lw_index, bed_list
  bed_list = SCAPE.robot_beds[$(this).attr('data-bed')]
  lw_index = bed_list.indexOf($(this).attr('data-labware'))
  bed_list.splice(lw_index, 1)
  if (bed_list.length === 0) {
    SCAPE.robot_beds[$(this).attr('data-bed')] = undefined
  }
  $(this).detach()
  $('#bed_list')
}

let checkResponse = function (response) {
  if ($('#bed_list').children().length === 0) {
    // We don't have any content
    $('#loadingModal').fadeOut(100)
  } else if (response.valid) {
    // Clear all bed error flags when valid
    clearFlagFromBeds(response.beds)
    pass()
  } else {
    // Set bed flags according to which are currently valid and which are not
    flagBeds(response.beds, response.message)
    fail()
  }
}

const flagBeds = function (beds, message) {
  let bad_beds = []
  $.each(beds, function (bed_id) {
    // here we check the validity of each bed in the hash returned from the ruby robot
    // valid_relationships method and if the bed is valid clear the error flags (in case the
    // bed was invalid in a previous validate cycle) or if invalid we set the error flags
    if (beds[bed_id]) {
      clearFlagFromBed(bed_id)
    } else {
      $('#bed_list li[data-bed="' + bed_id + '"]').addClass('bad_bed list-group-item-danger')
      bad_beds.push(bed_id)
    }
  })
  SCAPE.message('There were problems: ' + message, 'danger')
}

const clearFlagFromBeds = function (beds) {
  $.each(beds, function (bed_id) {
    if (beds[bed_id]) {
      clearFlagFromBed(bed_id)
    }
  })
}

const clearFlagFromBed = function (bed_id) {
  $('#bed_list li[data-bed="' + bed_id + '"]').removeClass('bad_bed list-group-item-danger')
}

let wait = function () {
  $('#loadingModal').fadeIn(100)
}

const pass = function () {
  $('#loadingModal').fadeOut(100)
  SCAPE.message('No problems detected!', 'success')
  $('#start-robot').prop('disabled', false)
}

const fail = function () {
  $('#loadingModal').fadeOut(100)
  $('#start-robot').prop('disabled', true)
}

$('#plate_scan').on('change', function () {
  let plate_barcode, bed_barcode, robot_barcode
  plate_barcode = this.value
  bed_barcode = $('#bed_scan').val()
  robot_barcode = $('#robot_scan').val()
  SCAPE.robot_scan = robot_barcode
  this.value = ''
  $('#bed_scan').val('')
  $('#bed_scan').focus()
  newScanned(bed_barcode, plate_barcode)
})

$('#robot_scan').on('change', function () {
  let robot_barcode
  robot_barcode = this.value
  newRobotScanned(robot_barcode)
})

$('#validate_layout').on('click', function () {
  wait()
  $.ajax({
    dataType: 'json',
    url: window.location.pathname + '/verify',
    type: 'POST',
    data: {
      bed_labwares: SCAPE.robot_beds,
      robot_barcode: SCAPE.robot_barcode,
    },
    success: function (data, _status) {
      checkResponse(data)
    },
  }).fail(function (_data, _status) {
    SCAPE.message(
      'The beds could not be validated. There may be network issues, or problems with Sequencescape.',
      'danger',
    )
    fail()
  })
})
