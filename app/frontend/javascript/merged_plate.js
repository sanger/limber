import jQuery from 'jquery'
import { disableEnterKeySubmit } from '@/javascript/lib/disable_enter_key_submit.js'
;(function ($, _exports, undefined) {
  'use strict'

  $(function (_event) {
    disableEnterKeySubmit('#merged-plate-page', '#new_plate')
  })
})(jQuery, window)
