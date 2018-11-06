(function($, exports, undefined){
  "use strict";

  // Declared as var  rather than const due to issues with const in strict mode
  // in the older versions of Chrome (34) used in the labs.
  var SOURCE_STATES = ["passed", "qc_complete"]

  $(function(event) {

    if ($('#pooled-tubes-from-whole-plates').length === 0) { return };

    //= require lib/array_fill_polyfill

    var Pooler = function(plate_number, button) {
      this.tags = Array(plate_number).fill([]);
      //this.plates = new Array(4);
      this.button = button;
    };

    // Inefficient and limited Set polyfill for phantomjs and IE10
    if (Set === undefined) {
      var Set = function() { this.array = []; };

      Set.prototype = {
        // Agh! Can't even use includes in older browsers
        has: function(element) { return this.array.indexOf(element) !== -1; },
        add: function(element) { this.array.push(element); }
      }
    }

    Pooler.prototype = {
      retrieveLabware : function(plate) {
        this.disable();
        plate.ajax = $.ajax({
          dataType: "json",
          url: '/search/',
          type: 'POST',
          data: 'plate_barcode='+plate.value,
          success: function(data,status) { plate.checkLabware(data, status); }
        }).fail(function(data,status) {
          if (status!=='abort') {
            SCAPE.message('Some problems: '+ status,'invalid');
            plate.badLabware();
          }
        });
      },
      checkLabwares : function() {
        if ($('.wait-plate, .bad-plate').length === 0) {
          this.enable();
        } else {
          this.disable();
        }
      },
      record: function(plate, position) {
        this.tags[position] = plate.tags;
        return this.noDupes();
      },
      clearTags: function(position) {
        this.tags[position] = [];
      },
      disable: function() { this.button.attr('disabled', 'disabled'); },
      enable: function() { this.button.attr('disabled', null); },
      noDupes: function() {
        var set = new Set;
        return this.tags.every(function(tag_set) {
          return tag_set.every(function(tag) {
            var tagsAsString = String(tag);
            if (set.has(tagsAsString)) {
              return false
            } else {
              set.add(tagsAsString);
              return true
            }
          })
        })
      }
    }

    var pooler = new Pooler($('.plate-box').length, $('#create-labware'))

    $('.plate-box').on('change', function() {
      // When we scan in a plate
      if (this.value === "") {
        this.scanLabware();
      } else {
        this.waitLabware();
        pooler.retrieveLabware(this); };
    });

    $('.plate-box').each(function(){

      $.extend(this, {
        /*
          Our plate beds
        */
        waitLabware : function() {
          this.clearLabware();
          this.plateContainer().removeClass('good-plate bad-plate scan-plate');
          this.plateContainer().addClass('wait-plate');
          $('#summary_tab').addClass('ui-disabled');
        },
        scanLabware : function() {
          this.clearLabware();
          this.plateContainer().removeClass('good-plate wait-plate bad-plate');
          this.plateContainer().addClass('scan-plate');
          pooler.checkLabwares();
        },
        badLabware : function() {
          this.clearLabware();
          this.plateContainer().removeClass('good-plate wait-plate scan-plate');
          this.plateContainer().addClass('bad-plate');
          $('#summary_tab').addClass('ui-disabled');
        },
        goodLabware : function() {
          this.plateContainer().removeClass('bad-plate wait-plate scan-plate');
          this.plateContainer().addClass('good-plate');
          pooler.checkLabwares();
        },
        plateContainer : function() {
          return $(this).closest('.plate-container');
        },
        checkLabware : function(data,status) {
          var response = data[this.dataset.labwareType];
          if (SOURCE_STATES.indexOf(response.state) === -1) {
            this.badLabware();
            SCAPE.message('Scanned '+ this.dataset.labwareType + 's are unsuitable','invalid');
          } else {
            if (pooler.record(response, $(this).data('position'))) {
              this.goodLabware();
            } else {
              this.badLabware();
              SCAPE.message('Scanned '+ this.dataset.labwareType + 's have matching tags','invalid');
            }
          };
        },
        clearLabware : function() {
          pooler.clearTags($(this).data('position'));
        }
      })
    })
  });
})(jQuery,window);
