function disable_enter_key_submit(elementSelectorToIdentifyPage, formWrapperElement){
  // If we are not on the specified page, don't set anything up.
  if ($(elementSelectorToIdentifyPage).length === 0) { return }

  // Build up a list of all fields we may want to tab through.
  // Only include fields nested under the specified element.
  var fields = $(formWrapperElement).find("input[type=text],input[type=submit]")

  // Then to each of the text fields, capture the enter event,
  // and stop it from auto-submitting the form.
  // This supports the scanners which are configured to send
  // and enter, rather than a tab. We also set the focus
  // to the next field, to ensure it behaves the same
  fields.each(function (index, field) {
    if($(field).is('input[type=text]')) {
      $(field).on("keypress", function(e) {
        var code = e.key;
        if (code === 'Enter') {
          e.preventDefault() // Stop the form submitting
          $(fields[index+1]).focus() // Emulate a tab
        }
      });
    }
  })
}