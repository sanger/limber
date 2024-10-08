import $ from 'jquery'
import tagStatusCollector from '@/javascript/lib/tag_collector.js'
import validator from '@/javascript/lib/validator.js'
import SCAPE from '@/javascript/lib/global_message_system.js'

const configElement = document.getElementById('labware-creator-config')
const tagPlatesList = JSON.parse(configElement.dataset.tagPlatesList)
const dualRequired = configElement.dataset.dualRequired === 'true'
const enforceSameTemplateWithinPool = configElement.dataset.enforceSameTemplateWithinPool === 'true'

Object.assign(SCAPE, {
  tag_plates_list: tagPlatesList,
  dualRequired: dualRequired,
  enforceSameTemplateWithinPool: enforceSameTemplateWithinPool,
})

// Previous content from tag_by_tag_plate.js follows below

// TAG CREATION
let qcableLookup

//= require lib/ajax_support

// Set up some null objects
let unknownTemplate = { unknown: true, dual_index: false }
let unknownQcable = { template_uuid: 'not-loaded' }

qcableLookup = function (barcodeBox, collector) {
  if (barcodeBox.length === 0) {
    return false
  }

  let qc_lookup = this
  this.inputBox = barcodeBox

  // the `data` attribute is set when declaring the element in tagged_plate.html.erb
  this.infoPanel = $('#' + barcodeBox.data('info-panel'))
  this.requiresDualIndexing = barcodeBox.data('requires-dual-indexing')
  this.approvedTypes = SCAPE[barcodeBox.data('approved-list')]
  this.required = this.inputBox[0].required

  // add an onchange event to the box, to look up the plate
  this.inputBox.on('change', function () {
    qc_lookup.resetStatus()
    qc_lookup.requestPlate(this.value)
  })
  this.monitor = collector.register(!this.required, this)

  // set initial values for the tag plate data
  this.qcable = unknownQcable
  this.template = unknownTemplate
}

qcableLookup.prototype = {
  resetStatus: function () {
    this.monitor.fail()
    this.infoPanel.find('dd').text('')
    this.infoPanel.find('input').val(null)
  },
  requestPlate: function (_barcode) {
    if (this.inputBox.val() === '' && !this.required) {
      return this.monitor.pass()
    }
    // find the qcable (tag plate) based on the barcode scanned in by the user
    $.ajax({
      type: 'POST',
      dataType: 'json',
      url: '/search/qcables',
      data: 'qcable_barcode=' + this.inputBox.val(),
    }).then(this.success(), this.error())
  },
  success: function () {
    let qc_lookup = this
    return function (response) {
      if (response.error) {
        qc_lookup.message(response.error, 'danger')
      } else if (response.qcable) {
        // if response is as expected, load some data
        qc_lookup.plateFound(response.qcable)
      } else {
        qc_lookup.message('An unexpected response was received. Please contact support.', 'danger')
      }
    }
  },
  error: function () {
    let qc_lookup = this
    return function () {
      qc_lookup.message(
        'The barcode could not be found. There may be network issues, or problems with Sequencescape.',
        'danger',
      )
    }
  },
  validators: [
    // `t` is a qcableLookup object
    // The data for t.template comes from app/models/labware_creators/tagging/tag_collection.rb
    // t.template.dual_index is true if the scanned tag plate contains both i5 and i7 tags together in its wells (is a UDI plate)
    // t.requiresDualIndexing is true if there are multiple source plates from the submission, which will be pooled...
    // ... and therefore an i5 tag (tag 2) is needed (from a UDI plate)
    new validator(function (t) {
      return t.qcable.state == 'available'
    }, 'The scanned item is not available.'),
    new validator(function (t) {
      return !t.template.unknown
    }, 'It is an unrecognised template.'),
    new validator(function (t) {
      return t.template.approved
    }, 'It is not approved for use with this pipeline.'),
    new validator(function (t) {
      return !(t.requiresDualIndexing && t.template.used && t.template.dual_index)
    }, 'This template has already been used.'),
    new validator(function (t) {
      return !(t.requiresDualIndexing && !t.template.dual_index)
    }, 'Pool is spread across multiple plates. UDI plates must be used.'),
    new validator(function (t) {
      return SCAPE.enforceSameTemplateWithinPool ? t.template.matches_templates_in_pool : true
    }, "It doesn't match those already used for other plates in this submission pool."),
  ],
  //
  // The major function that runs when a tag plate is scanned into the box
  // Loads tag plate data into `qcable` and `template`
  // Adds visible information to the information panel
  // Validates whether the tag plate is suitable
  // Updates the plate diagram with tag numbers
  //
  plateFound: function (qcable) {
    this.qcable = qcable
    this.template = this.approvedTypes[qcable.template_uuid] || unknownTemplate
    this.populateData()

    if (this.validPlate()) {
      this.message('The ' + qcable.qcable_type + ' is suitable.', 'success')
      SCAPE.update_layout()
      this.monitor.pass()
    } else {
      this.message(' The ' + qcable.qcable_type + ' is not suitable.' + this.errors, 'danger')
      this.monitor.fail()
    }
  },
  populateData: function () {
    // add information retrieved about the scanned tag plate to the information panel for the user to see
    this.infoPanel.find('dd.lot-number').text(this.qcable.lot_number)
    this.infoPanel.find('dd.template').text(this.qcable.tag_layout)
    this.infoPanel.find('dd.state').text(this.qcable.state)
    this.infoPanel.find('.asset_uuid').val(this.qcable.asset_uuid)
    this.infoPanel.find('.template_uuid').val(this.qcable.template_uuid)
  },
  validPlate: function () {
    // run through the `validators`, and collect any errors
    this.errors = ''
    for (let i = 0; i < this.validators.length; i += 1) {
      let response = this.validators[i].validate(this)
      if (!response.valid) {
        this.errors += ' ' + response.message
      }
    }
    return this.errors === ''
  },
  message: function (message, status) {
    this.infoPanel
      .find('.qc_validation_report')
      .empty()
      .append(
        $(document.createElement('div'))
          .addClass('alert')
          .addClass('alert-' + status)
          .text(message),
      )
  },
  dual: function () {
    return this.template.dual_index
  },
  errors: '',
}

let qcCollector = new tagStatusCollector(
  SCAPE.dualRequired,
  function () {
    $('#submit-summary').text('Marks the tag sources as used, and convert the tag plate.')
    $('#plate_submit').prop('disabled', false)
  },
  function (message) {
    $('#submit-summary').text(message)
    $('#plate_submit').prop('disabled', true)
  },
)

new qcableLookup($('#plate_tag_plate_barcode'), qcCollector)

/* Disables form submit (eg. by enter) if the button is disabled. Seems safari doesn't do this by default */
$('form#plate_new').on('submit', function () {
  return !$('input#plate_submit')[0].disabled
})

$.extend(SCAPE, {
  fetch_tags: function () {
    let selected_layout = $('#plate_tag_plate_template_uuid').val()
    if (SCAPE.tag_plates_list[selected_layout] === undefined) {
      return $([])
    } else {
      return $(SCAPE.tag_plates_list[selected_layout].tags)
    }
  },
  update_layout: function () {
    let tags = this.fetch_tags()

    tags.each(function (_index) {
      $('#tagging-plate #aliquot_' + this[0])
        .hide('fast')
        .text(this[1][1])
        .addClass('aliquot colour-' + this[1][0])
        .addClass('tag-' + this[1][1])
        .show('fast')
    })
  },
})
SCAPE.update_layout()
