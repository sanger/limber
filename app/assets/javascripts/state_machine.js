(function($, exports, undefined){
  "use strict";

  $.ajaxSetup({
    beforeSend: function(xhr) {
      xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
    }
  });

  var Events = {
    on: function(){
      if (!this.o) this.o = $({});

      this.o.on.apply(this.o, arguments);
    },

    trigger: function(){
      if (!this.o) this.o = $({});

      this.o.trigger.apply(this.o, arguments);
    }
  };

  var StateMachine = function(){};

  StateMachine.fn = StateMachine.prototype;

  $.extend(StateMachine.fn, Events);

  StateMachine.fn.add = function(controller){
    this.on("change", function(e, current){
      if (controller == current)
        controller.activate();
      else
        controller.deactivate();
    });

    controller.active = $.proxy(function(){
      this.trigger("change", controller);
    }, this);
  };

  exports.StateMachine = StateMachine;
})(jQuery,window);
