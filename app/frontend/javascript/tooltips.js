import jQuery from 'jquery'
jQuery(function () {
  jQuery('[data-bs-toggle="tooltip"]').map(function (elem) {
    elem.enable()
  })
})
