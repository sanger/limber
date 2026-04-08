import $ from 'jquery'
import SCAPE from '@/javascript/lib/global_message_system.js'

const SOURCE_STATES = ['passed', 'qc_complete']

//= require lib/array_fill_polyfill

let Pooler = function (labware_number, button) {
  this.tags = Array(labware_number).fill([])
  this.labware_details = Array(labware_number).fill({})
  this.clashing_tags = null
  this.button = button
}

// Inefficient and limited Set polyfill for phantomjs and IE10
if (Set === undefined) {
  let Set = function () {
    this.array = []
  }

  Set.prototype = {
    // Agh! Can't even use includes in older browsers
    has: function (element) {
      return this.array.indexOf(element) !== -1
    },
    add: function (element) {
      this.array.push(element)
    },
  }
}

Pooler.prototype = {
  retrieveLabware: function (labware) {
    this.disable()
    labware.ajax = $.ajax({
      dataType: 'json',
      url: '/search/',
      type: 'POST',
      data: 'plate_barcode=' + labware.value,
      success: function (data, status) {
        labware.checkLabware(data, status, labware.value)
      },
    }).fail(function (data, status) {
      if (status !== 'abort') {
        SCAPE.message('Some problems: ' + status, 'invalid')
        labware.badLabware()
      }
    })
  },
  checkLabwares: function () {
    if ($('.wait-labware, .bad-labware').length === 0) {
      this.enable()
    } else {
      this.disable()
    }
  },
  record: function (labware, position, scanned_barcode) {
    this.tags[position] = labware.tags
    this.labware_details[position] = {
      human_barcode: labware.barcode,
      machine_barcode: scanned_barcode,
      tags: labware.tags.map((tag) => String(tag)),
    }
    return this.noDupes()
  },
  clearTags: function (position) {
    this.tags[position] = []
    this.labware_details[position] = {}
    this.clashing_tags = null
  },
  disable: function () {
    this.button.attr('disabled', 'disabled')
  },
  enable: function () {
    this.button.attr('disabled', null)
  },
  noDupes: function () {
    let set = new Set()
    let poolerObj = this
    return this.tags.every(function (tag_set) {
      return tag_set.every(function (tag) {
        let tagsAsString = String(tag)
        if (set.has(tagsAsString)) {
          poolerObj.clashing_tags = tagsAsString
          return false
        } else {
          set.add(tagsAsString)
          return true
        }
      })
    })
  },
}

let pooler = new Pooler($('.labware-box').length, $('#create-labware'))

$('.labware-box').on('change', function () {
  // When we scan in a labware
  if (this.value === '') {
    this.scanLabware()
  } else {
    this.waitLabware()
    pooler.retrieveLabware(this)
  }
})

$('.labware-box').each(function () {
  $.extend(this, {
    waitLabware: function () {
      this.clearLabware()
      this.labwareContainer().removeClass('good-labware bad-labware scan-labware')
      this.labwareContainer().addClass('wait-labware')
      $('#summary_tab').addClass('ui-disabled')
    },
    scanLabware: function () {
      this.clearLabware()
      this.labwareContainer().removeClass('good-labware wait-labware bad-labware')
      this.labwareContainer().addClass('scan-labware')
      pooler.checkLabwares()
    },
    badLabware: function () {
      this.clearLabware()
      this.labwareContainer().removeClass('good-labware wait-labware scan-labware')
      this.labwareContainer().addClass('bad-labware')
      $('#summary_tab').addClass('ui-disabled')
    },
    goodLabware: function () {
      this.labwareContainer().removeClass('bad-labware wait-labware scan-labware')
      this.labwareContainer().addClass('good-labware')
      pooler.checkLabwares()
    },
    labwareContainer: function () {
      return $(this).closest('.labware-container')
    },
    checkLabware: function (data, status, scanned_barcode) {
      let response = data[this.dataset.labwareType]
      if (SOURCE_STATES.indexOf(response.state) === -1) {
        this.badLabware()
        const msg = `Scanned ${this.dataset.labwareType}s are currently in a '${response.state}' state when they should be in one of: ${SOURCE_STATES.join(', ')}.`
        SCAPE.message(msg, 'invalid')
      } else {
        let position = $(this).data('position')
        if (pooler.record(response, position, scanned_barcode)) {
          this.goodLabware()
        } else {
          let clashing_labware_barcodes = this.findClashingLabwares()

          this.badLabware()

          let msg =
            'The scanned ' +
            this.dataset.labwareType +
            ' contains tags that would clash with those in other ' +
            this.dataset.labwareType +
            's in the pool. Tag clashes found between: ' +
            clashing_labware_barcodes

          SCAPE.message(msg, 'invalid')
        }
      }
    },
    findClashingLabwares: function () {
      let clashing_labwares = []

      Object.keys(pooler.labware_details).forEach(function (key) {
        let current_labware_details = pooler.labware_details[key]
        // skip empty labware locations
        if (current_labware_details.tags == undefined) {
          return
        }

        // check for clashing tags
        if (current_labware_details.tags.includes(pooler.clashing_tags)) {
          let human_barcode = String(current_labware_details.human_barcode)
          let machine_barcode = String(current_labware_details.machine_barcode)
          clashing_labwares.push('' + human_barcode + ' (' + machine_barcode + ')')
        }
      })

      return clashing_labwares.join(' and ')
    },
    clearLabware: function () {
      SCAPE.message('', null)
      pooler.clearTags($(this).data('position'))
    },
  })
})
