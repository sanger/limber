import $ from 'jquery'
$.ajaxSetup({
  beforeSend: function (xhr) {
    xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
  },
})
