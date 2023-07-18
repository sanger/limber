;(function ($, exports, undefined) {
  'use strict'

  // Declared as var  rather than const due to issues with const in strict mode
  // in the older versions of Chrome (34) used in the labs.
  var SOURCE_STATES = ['passed', 'qc_complete']

  $(function (event) {
    if ($('#pooled-tubes-from-whole-plates').length === 0) {
      return
    }

    //= require lib/array_fill_polyfill

    var Pooler = function (labware_number, button) {
      this.tags = Array(labware_number).fill([])
      this.labware_details = Array(labware_number).fill({})
      this.clashing_tags = null
      this.button = button
    }

    // Inefficient and limited Set polyfill for phantomjs and IE10
    if (Set === undefined) {
      var Set = function () {
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
        if ($('.wait-plate, .bad-plate').length === 0) {
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
        var set = new Set()
        var poolerObj = this
        return this.tags.every(function (tag_set) {
          return tag_set.every(function (tag) {
            var tagsAsString = String(tag)
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

    var pooler = new Pooler($('.plate-box').length, $('#create-labware'))

    $('.plate-box').on('change', function () {
      // When we scan in a labware
      if (this.value === '') {
        this.scanLabware()
      } else {
        this.waitLabware()
        pooler.retrieveLabware(this)
      }
    })

    $('.plate-box').each(function () {
      $.extend(this, {
        waitLabware: function () {
          this.clearLabware()
          this.labwareContainer().removeClass('good-plate bad-plate scan-plate')
          this.labwareContainer().addClass('wait-plate')
          $('#summary_tab').addClass('ui-disabled')
        },
        scanLabware: function () {
          this.clearLabware()
          this.labwareContainer().removeClass('good-plate wait-plate bad-plate')
          this.labwareContainer().addClass('scan-plate')
          pooler.checkLabwares()
        },
        badLabware: function () {
          this.clearLabware()
          this.labwareContainer().removeClass('good-plate wait-plate scan-plate')
          this.labwareContainer().addClass('bad-plate')
          $('#summary_tab').addClass('ui-disabled')
        },
        goodLabware: function () {
          this.labwareContainer().removeClass('bad-plate wait-plate scan-plate')
          this.labwareContainer().addClass('good-plate')
          pooler.checkLabwares()
        },
        labwareContainer: function () {
          return $(this).closest('.plate-container')
        },
        checkLabware: function (data, status, scanned_barcode) {
          var response = data[this.dataset.labwareType]
          if (SOURCE_STATES.indexOf(response.state) === -1) {
            this.badLabware()
            SCAPE.message('Scanned ' + this.dataset.labwareType + 's are unsuitable', 'invalid')
          } else {
            var position = $(this).data('position')
            if (pooler.record(response, position, scanned_barcode)) {
              this.goodLabware()
            } else {
              var clashing_labware_barcodes = this.findClashingLabwares()

              this.badLabware()

              var msg = 'The scanned ' +
                        this.dataset.labwareType +
                        ' contains tags that would clash with those in other ' +
                        this.dataset.labwareType +
                        's in the pool. Tag clashes found between: ' +
                        clashing_labware_barcodes

              SCAPE.message(msg, 'invalid')
            }
          }
        },
        findClashingLabwares: function() {
          var clashing_labwares = []

          Object.keys(pooler.labware_details).forEach(function (key) {
            var current_labware_details = pooler.labware_details[key]
            // skip empty labware locations
            if (current_labware_details.tags == undefined) {
              return
            }

            // check for clashing tags
            if (current_labware_details.tags.includes(pooler.clashing_tags)) {
              var human_barcode = String(current_labware_details.human_barcode)
              var machine_barcode = String(current_labware_details.machine_barcode)
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
  })
})(jQuery, window)
