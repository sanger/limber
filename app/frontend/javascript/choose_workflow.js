import jQuery from 'jquery'

import { disableEnterKeySubmit } from './lib/disable_enter_key_submit.js'
;(function ($, _exports, undefined) {
  'use strict'

  $(function (_event) {
    disableEnterKeySubmit('#choose_workflow_card', '#submission_forms')
  })
})(jQuery, window)
