import { disableEnterKeySubmit } from './lib/disable_enter_key_submit.js'
;(function ($, exports, undefined) {
  'use strict'

  $(function (_event) {
    disableEnterKeySubmit('#merged-plate-page', '#new_plate')
  })
})(jQuery, window)
