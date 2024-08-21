'use strict'

import $ from 'jquery'

//= require lib/ajax_support

let Events = {
  on: function () {
    if (!this.o) this.o = $({})

    this.o.on.apply(this.o, arguments)
  },

  trigger: function () {
    if (!this.o) this.o = $({})

    this.o.trigger.apply(this.o, arguments)
  },
}

let StateMachine = function () {}

StateMachine.fn = StateMachine.prototype

$.extend(StateMachine.fn, Events)

StateMachine.fn.add = function (controller) {
  this.on('change', function (e, current) {
    if (controller == current) controller.activate()
    else controller.deactivate()
  })

  controller.active = $.proxy(function () {
    this.trigger('change', controller)
  }, this)
}
export { StateMachine }
