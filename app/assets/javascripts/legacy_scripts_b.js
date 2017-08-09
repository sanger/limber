(function($, exports, undefined){
  "use strict";

  // Our robot controller

  $.extend(SCAPE, {
    retrievePlate : function(bed) {
      bed.ajax = $.ajax({
        dataType: "json",
        url: '/search/retrieve_parent',
        data: 'barcode='+bed.value,
        success: function(data,status) { bed.checkPlate(data,status) }
      }).fail(function(data,status) { if (status!=='abort') {bed.badPlate();} });
    }
  })
})(jQuery,window);
