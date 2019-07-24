
// Global SCAPE.message method
(function($, exports, undefined){
  "use strict";

  if (exports.SCAPE === undefined) { exports.SCAPE = {}; }

   exports.SCAPE.message = function(message,status) {
      $('#validation_report').empty().append(
        $(document.createElement('div')).
          addClass('alert').
          addClass('alert-'+status).
          text(message)
        );
    }

})(jQuery,window);
