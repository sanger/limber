(function($, exports, undefined){
  "use strict";

  // Declared as var  rather than const due to issues with const in strict mode
  // in the older versions of Chrome (34) used in the labs.
  var PlateViewModel = function(plateElement) {
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
  };

  // Declared as var  rather than const due to issues with const in strict mode
  // in the older versions of Chrome (34) used in the labs.
  const limberPlateView = function() {
    var plateElement = $(this);

    var control = $('#plate-view-control');

    var viewModel = new PlateViewModel(plateElement);

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

  // Extend jQuery prototype...
  $.extend($.fn, { limberPlateView:    limberPlateView });
  $(function(_event) { $('#plate-show-page #plate').limberPlateView() });


  // ########################################################################
  // # Page events....
  $(function(){
    //= require lib/keycodes
    // Trap the carriage return sent by barcode scanner
    $(document).on("keydown", ".plate-barcode", function(event) {
      var code=event.charCode || event.keyCode;
      // Check for carrage return (key code ENTER_KEYCODE)
      if ((code === ENTER_KEYCODE)||(code === TAB_KEYCODE)) {
        if ($(event.currentTarget).val().length > 0) {
          $(event.currentTarget).closest('.plate-search-form').submit();
        }
      }
    });
  });
})(jQuery, window);
