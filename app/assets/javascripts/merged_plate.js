(function($, exports, undefined){
  'use strict'

  $(function(_event) {
    // If we are not on the multi-plate pooling page, don't set anything up.
    if ($('#merged-plate-page').length === 0) { return }

    // Build up a list of all fields we may want to tab through.
    var fields = $('#new_plate').find("input[type=text],input[type=submit]")

    // Then to each of the text fields, capture the enter event,
    // and stop it from auto-submitting the form.
    // This supports the scanners which are configured to send
    // and enter, rather than a tab. We also set the focus
    // to the next field, to ensure it behaves the same
    fields.filter('input[type=text]').each(function (index, field) {
      $(field).on("keydown", function(e) {
        var code = e.charCode || e.keyCode;
        if (code === ENTER_KEYCODE) {
          e.preventDefault() // Stop the form submitting
          $(fields[index+1]).focus() // Emulate a tab
        }
      });
    })
  })
})(jQuery, window)
