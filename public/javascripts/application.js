$(function() {

  $('.tabs').tabs();

  var App = Spine.Controller.create({
    init: function(){
      this.routes({
        "plate-summary": function(){
          $('#plate-tabs').tabs('select',0);
        },

        "plate-printing": function() {
          $('#plate-tabs').tabs('select', 1);
        },

        "plate-state": function(){
          $('#plate-tabs').tabs('select', 2);
        }
      });
    }
  }).init();

  Spine.Route.setup();

});
