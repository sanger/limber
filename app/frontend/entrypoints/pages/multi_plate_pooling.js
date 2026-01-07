import $ from 'jquery'
import SCAPE from '@/javascript/lib/global_message_system.js'
import { sendDuplicateTagGroupsWarning } from './duplicateTagGroupsWarning'

const WELLS_IN_COLUMN_MAJOR_ORDER = [
  'A1',
  'B1',
  'C1',
  'D1',
  'E1',
  'F1',
  'G1',
  'H1',
  'A2',
  'B2',
  'C2',
  'D2',
  'E2',
  'F2',
  'G2',
  'H2',
  'A3',
  'B3',
  'C3',
  'D3',
  'E3',
  'F3',
  'G3',
  'H3',
  'A4',
  'B4',
  'C4',
  'D4',
  'E4',
  'F4',
  'G4',
  'H4',
  'A5',
  'B5',
  'C5',
  'D5',
  'E5',
  'F5',
  'G5',
  'H5',
  'A6',
  'B6',
  'C6',
  'D6',
  'E6',
  'F6',
  'G6',
  'H6',
  'A7',
  'B7',
  'C7',
  'D7',
  'E7',
  'F7',
  'G7',
  'H7',
  'A8',
  'B8',
  'C8',
  'D8',
  'E8',
  'F8',
  'G8',
  'H8',
  'A9',
  'B9',
  'C9',
  'D9',
  'E9',
  'F9',
  'G9',
  'H9',
  'A10',
  'B10',
  'C10',
  'D10',
  'E10',
  'F10',
  'G10',
  'H10',
  'A11',
  'B11',
  'C11',
  'D11',
  'E11',
  'F11',
  'G11',
  'H11',
  'A12',
  'B12',
  'C12',
  'D12',
  'E12',
  'F12',
  'G12',
  'H12',
]

const SOURCE_STATES = ['passed', 'qc_complete']

$.extend(SCAPE, {
  // Make an AJAX call to limber to find the plate.
  // Call made to the searches controller, when then redirects the the plate
  // show page. Which renders a json template containing the necessary information
  retrievePlate: function (plate) {
    plate.ajax = $.ajax({
      dataType: 'json',
      url: '/search/',
      type: 'POST',
      data: 'plate_barcode=' + plate.value,
      success: function (data, status) {
        plate.checkPlate(data, status)
      },
    }).fail(function (data, status) {
      if (status !== 'abort') {
        plate.badPlate()
      }
    })
  },
  // Enable the create labware button if all plates are valid
  // disables it otherwise
  // Called when any plate updates its state
  checkPlates: function () {
    if ($('.wait-labware, .bad-labware').length === 0) {
      $('#create-labware').attr('disabled', null)
    } else {
      $('#create-labware').attr('disabled', 'disabled')
    }
  },
  plates: [],
})

$('.labware-box').on('change', function () {
  // When we scan in a plate
  if (this.value === '') {
    this.scanPlate()
    updateView()
  } else {
    this.waitPlate()
    $('#create-labware').attr('disabled', 'disabled')
    SCAPE.retrievePlate(this)
  }
})

$('.labware-box').each(function () {
  $.extend(this, {
    // Sets the wait state, indicating an AJAX request is in progress
    waitPlate: function () {
      this.clearPlate()
      $(this).closest('.labware-container').removeClass('good-labware bad-labware scan-labware')
      $(this).closest('.labware-container').addClass('wait-labware')
      $('#summary_tab').addClass('ui-disabled')
    },
    // Sets the 'waiting for content' state, which represents no content
    scanPlate: function () {
      this.clearPlate()
      $(this).closest('.labware-container').removeClass('good-labware wait-labware bad-labware')
      $(this).closest('.labware-container').addClass('scan-labware')
      SCAPE.checkPlates()
    },
    // Sets an invalid state, indicating the scanned barcode isn't suitable
    badPlate: function () {
      this.clearPlate()
      $(this).closest('.labware-container').removeClass('good-labware wait-labware scan-labware')
      $(this).closest('.labware-container').addClass('bad-labware')
      $('#summary_tab').addClass('ui-disabled')
    },
    // Sets a valid state, indicating the scanned barcode is good to process
    goodPlate: function () {
      $(this).closest('.labware-container').removeClass('bad-labware wait-labware scan-labware')
      $(this).closest('.labware-container').addClass('good-labware')
      SCAPE.checkPlates()
    },
    // Passed the response of an ajax call and determines if the plate is suitable
    // Currently just checks the plate state.
    // Good plates are stored in the plate array.
    // Regardless of outcome, the preview is updated via updateView
    checkPlate: function (data, _status) {
      if (SOURCE_STATES.indexOf(data.plate.state) === -1) {
        this.badPlate()
      } else {
        SCAPE.plates[$(this).data('position')] = data.plate
        this.goodPlate()
      }
      updateView()
    },
    // Removes any previously scanned plate from the array
    clearPlate: function () {
      SCAPE.plates[$(this).data('position')] = undefined
    },
  })
})

// Counts the total number of pools on the plate
SCAPE.totalPools = function () {
  let poolCount = 0
  for (let plateIndex = 0; plateIndex < SCAPE.plates.length; plateIndex += 1) {
    if (SCAPE.plates[plateIndex] !== undefined) {
      let preCapPools = SCAPE.plates[plateIndex].preCapPools
      poolCount += walkPreCapPools(preCapPools, function () {})
    }
  }
  return poolCount
}

SCAPE.calculatePreCapPools = function () {
  return SCAPE.totalPools() <= 96
}

SCAPE.newAliquot = function (poolNumber, aliquotText) {
  let poolNumberInt = parseInt(poolNumber, 10)

  return $(document.createElement('div'))
    .addClass('aliquot colour-' + (poolNumberInt + 1))
    .text(aliquotText || '\u00A0')
    .hide()
}

const walkPreCapPools = function (preCapPools, block) {
  let poolNumber = -1
  for (let capPool of preCapPools) {
    poolNumber++
    block(capPool.wells, poolNumber)
  }
  return poolNumber + 1
}

let renderPoolingSummary = function (plates) {
  let capPoolOffset = 0

  for (let plate of plates) {
    if (plate === undefined) {
      // Nothing
    } else {
      let preCapPools = plate.preCapPools
      capPoolOffset += walkPreCapPools(preCapPools, function (wells, poolNumber) {
        let destinationWell = WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset + poolNumber]
        let listElement = $('<li/>')
          .text(destinationWell)
          .append('<div class="pool-size">' + wells.length + '</div>')
          .append('<div class="pool-info">' + plate.barcode + ': ' + wells.join(', ') + '</div>')
        $('#pooling-summary').append(listElement)
      })
    }
  }
}

SCAPE.renderDestinationPools = function () {
  $('.destination-plate .well').empty()

  let capPoolOffset = 0
  for (let plate of SCAPE.plates) {
    if (plate !== undefined) {
      let well
      capPoolOffset += walkPreCapPools(plate.preCapPools, function (wells, poolNumber) {
        well = $('.destination-plate .' + WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset + poolNumber])
        if (wells.length) well.append(SCAPE.newAliquot(capPoolOffset + poolNumber, wells.length))
      })
    }
  }
}

SCAPE.renderSourceWells = function () {
  let capPoolOffset = 0
  for (let plateIndex = 0; plateIndex < SCAPE.plates.length; plateIndex += 1) {
    if (SCAPE.plates[plateIndex] === undefined) {
      $('.plate-id-' + plateIndex).hide()
    } else {
      let preCapPools = SCAPE.plates[plateIndex].preCapPools
      let barcode = SCAPE.plates[plateIndex].barcode
      $('.plate-id-' + plateIndex).show()
      $('.plate-id-' + plateIndex + ' .well').empty()
      $('.plate-id-' + plateIndex + ' caption').text(barcode)
      $('#well-transfers-' + plateIndex).detach()

      let newInputs = $(document.createElement('div')).attr('id', 'well-transfers-' + plateIndex)
      capPoolOffset += walkPreCapPools(preCapPools, function (wells, poolNumber) {
        let newInput, well

        for (let wellName of wells) {
          well = $('.plate-id-' + plateIndex + ' .' + wellName)
          well.append(
            SCAPE.newAliquot(capPoolOffset + poolNumber, WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset + poolNumber]),
          )

          newInput = $(document.createElement('input'))
            .attr('name', 'plate[transfers][' + SCAPE.plates[plateIndex].uuid + '][' + wellName + ']')
            .attr('type', 'hidden')
            .val(WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset + poolNumber])

          newInputs.append(newInput)
        }
      })
      $('#new_plate').append(newInputs)
    }
  }
}

let plateSummaryHandler = function () {
  SCAPE.renderSourceWells()
  SCAPE.renderDestinationPools()

  $('.aliquot').fadeIn('slow')

  $('.well').each(function () {
    // Handles wells which are part of multiple pre-capture pools
    // Causes them to animate between the available states
    if ($(this).children().length < 2) {
      return
    }

    this.pos = 0

    this.slide = function () {
      let scrollTo
      this.pos = (this.pos + 1) % $(this).children().length
      scrollTo = $(this).children()[this.pos].offsetTop - 5
      $(this).delay(1000).animate({ scrollTop: scrollTo }, 500, this.slide)
    }
    this.slide()
  })
}

const updateView = function () {
  if (SCAPE.calculatePreCapPools()) {
    plateSummaryHandler()
    $('#pooling-summary').empty()
    renderPoolingSummary(SCAPE.plates)
    SCAPE.message('Check pooling and create plate', 'valid')
    sendDuplicateTagGroupsWarning(SCAPE.plates)
  } else {
    // Pooling Went wrong
    $('#pooling-summary').empty()
    SCAPE.message('Too many pools for the target plate.', 'invalid')
  }
}
