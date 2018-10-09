(function($, exports, undefined){
  "use strict";

  //= require lib/keycodes

  // Set up the SCAPE namespace
  if (exports.SCAPE === undefined) { exports.SCAPE = {}; }

  $.extend(SCAPE, {

    dim: function() {
      $(this).fadeTo('fast', 0.2);
      return this;
    },

    linkCallbacks: $.Callbacks(),

    failWellToggleHandler:  function(event){
      $(event.currentTarget).hide('fast', function(){
        var failing = $(event.currentTarget).toggleClass('good failed').show().hasClass('failed');
        $(event.currentTarget).find('input:hidden')[failing ? 'attr' : 'removeAttr']('checked', 'checked');
      });
    },


  PlateViewModel: function(plateElement) {
    // Using the 'that' pattern...
    // ...'that' refers to the object created by this constructor.
    // ...'this' used in any of the functions will be set at runtime.
    var that          = this;
    that.plateElement = plateElement;

    that['pools-view'] = {
      activate: function(){
        $('#pools-information li').fadeIn('fast');
        that.plateElement.addClass('pool-colours');
        that.plateElement.find('.aliquot').
          removeClass('selected-aliquot dimmed');
      },

      deactivate: function(){
        that.plateElement.removeClass('pool-colours');
        that.plateElement.
          find('.aliquot').
          removeClass('selected-aliquot dimmed');
      }
    };
  },


  limberPlateView: function() {
    var plateElement = $(this);

    var control = $('#plate-view-control');

    var viewModel = new SCAPE.PlateViewModel(plateElement);

    control.find('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      var viewName = e.target.dataset.plateView;
      if (viewModel[viewName]) { viewModel[viewName].activate() }
    })

    control.find('a[data-toggle="tab"]').on('hide.bs.tab', function (e) {
      var viewName = e.target.dataset.plateView;
      if (viewModel[viewName]) { viewModel[viewName].deactivate() }
    })

    plateElement.on('click', '.aliquot', function(event) {
      var pool = $(event.currentTarget).data('pool');

      control.find('a[data-plate-view="pools-view"]').tab('show')

      plateElement.
        find('.aliquot[data-pool!='+pool+']').
        removeClass('selected-aliquot').addClass('dimmed');

      plateElement.
        find('.aliquot[data-pool='+pool+']').
        addClass('selected-aliquot').
        removeClass('dimmed');

        $('#pools-information li[data-pool!='+pool+']').
          fadeOut('fast').
          promise().
          done(function(){
            $('#pools-information li[data-pool='+pool+']').fadeIn('fast');
        });
    });

    // ...we will never break the chain...
    return this;
  }

  });

  // Extend jQuery prototype...
  $.extend($.fn, {
    limberPlateView:    SCAPE.limberPlateView,
    dim:                SCAPE.dim
  });


  // ########################################################################
  // # Page events....
  $(function(){

    // Trap the carriage return sent by barcode scanner
    $(document).on("keydown", ".plate-barcode", function(event) {
      var code=event.charCode || event.keyCode;
      // Check for carrage return (key code ENTER_KEYCODE)
      if ((code === ENTER_KEYCODE)||(code === TAB_KEYCODE)) {
        // Check that the value is 13 characters long like a barcode
        if ($(event.currentTarget).val().length === 13) {
          $(event.currentTarget).closest('.plate-search-form').submit();
        }
      }
    });
  });

  $(function(event) {
    // Set up the plate element as an illuminaBPlate...
    if ($('#plate-show-page').length === 0) { return };
    $('#plate').limberPlateView();
  });

  //= require lib/status_collector

})(jQuery, window);
