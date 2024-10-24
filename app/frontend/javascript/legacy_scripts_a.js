import $ from 'jquery'
import { ENTER_KEYCODE, TAB_KEYCODE } from '@/javascript/lib/keycodes.js'

// The majority of the code below is for the data-plate-view data attribute used to
// show differing colours based on the view selected, eg: pools, binning, etc.
// The pattern is to have a data-plate-view attribute on all tab links, but only have the
// required views defined below. This allows for easy extension of the views in the future.
let PlateViewModel = function (plateElement) {
  this['pools-view'] = {
    activate: function () {
      $('#pools-information li').fadeIn('fast')
      plateElement.addClass('pool-colours')
      plateElement.find('.aliquot').removeClass('selected-aliquot dimmed')
    },

    deactivate: function () {
      plateElement.removeClass('pool-colours')
      plateElement.find('.aliquot').removeClass('selected-aliquot dimmed')
    },
  }

  this['binned-view'] = {
    activate: function () {
      plateElement.addClass('binning-colours')
    },

    deactivate: function () {
      plateElement.removeClass('binning-colours')
    },
  }
}

let limberPlateView = function (defaultTab) {
  let plateElement = $(this)

  let control = $('#plate-view-control')

  let viewModel = new PlateViewModel(plateElement)

  control.find('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
    let viewName = e.target.dataset.plateView
    if (viewModel[viewName]) {
      viewModel[viewName].activate()
    }
  })

  control.find('a[data-toggle="tab"]').on('hide.bs.tab', function (e) {
    let viewName = e.target.dataset.plateView
    if (viewModel[viewName]) {
      viewModel[viewName].deactivate()
    }
  })

  // Activate the default tab from the URL hash
  // append '_tab' to the defaultTab to match the tab id, this prevents the page from jumping
  if (!defaultTab.endsWith('_tab')) {
    defaultTab += '_tab'
  }
  control.find('a[href="' + defaultTab + '"]').tab('show')

  plateElement.on('click', '.aliquot', function (event) {
    control.find('a[data-plate-view="pools-view"]').tab('show')

    let pool = $(event.currentTarget).data('pool')

    // Handle cases where pool is not defined to prevent errors
    if (pool === undefined || pool === '') return

    plateElement
      .find('.aliquot[data-pool!=' + pool + ']')
      .removeClass('selected-aliquot')
      .addClass('dimmed')

    plateElement
      .find('.aliquot[data-pool=' + pool + ']')
      .addClass('selected-aliquot')
      .removeClass('dimmed')

    $('#pools-information li[data-pool!=' + pool + ']')
      .fadeOut('fast')
      .promise()
      .done(function () {
        $('#pools-information li[data-pool=' + pool + ']').fadeIn('fast')
      })
  })

  // ...we will never break the chain...
  return this
}

// Extend jQuery prototype...
$.extend($.fn, { limberPlateView: limberPlateView })
$(function (_event) {
  $('#plate-show-page #plate').limberPlateView(window.location.hash)
})

// ########################################################################
// # Page events....
$(function () {
  //= require lib/keycodes
  // Trap the carriage return sent by barcode scanner
  $(document).on('keydown', '.plate-barcode', function (event) {
    let code = event.charCode || event.keyCode
    // Check for carrage return (key code ENTER_KEYCODE)
    if (code === ENTER_KEYCODE || code === TAB_KEYCODE) {
      if ($(event.currentTarget).val().length > 0) {
        $(event.currentTarget).closest('.plate-search-form').submit()
      }
    }
  })
})
