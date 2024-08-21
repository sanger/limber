import jQuery from 'jquery'
import { ENTER_KEYCODE, TAB_KEYCODE } from '@/javascript/lib/keycodes.js'
;(function ($, _exports, undefined) {
  'use strict'

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

    control.find('a[href="' + defaultTab + '"]').tab('show')

    plateElement.on('click', '.aliquot', function (event) {
      let pool = $(event.currentTarget).data('pool')

      control.find('a[data-plate-view="pools-view"]').tab('show')

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
})(jQuery, window)
