(function($, exports, undefined){
  "use strict";

  //= require lib/status_collector
  //= require lib/keycodes

  $(function(event) {

    if ($('#multi-tube-pooling-page').length === 0) { return };

    var newScanned, tubeCollector, siblingTube, barcodeRegister = {}

    //= require lib/ajax_support

    siblingTube = function(list_element,collector) {
      this.listElement = $(list_element);
      this.monitor = collector.register();
      barcodeRegister[list_element.dataset.barcode] = this;
    }

    siblingTube.prototype = {
      scanned: function() {
        this.monitor.pass();
        this.setState('good');
        this.listElement.find('input').val('1');
        this.setMessage('Scanned in and ready to go!');
      },
      setState: function(state) {
        for (var i = 0; i < this.states.length; i += 1) {
          if (state === this.states[i]) {
            this.listElement.addClass(this.states[i]+'-tube');
          } else {
            this.listElement.removeClass(this.states[i]+'-tube');
          }
        }
      },
      setMessage: function(message) {
        this.listElement.find('.tube_validation_report').text(message)
      },
      states: ['good','wait']
    }

    newScanned = function(tube_barcode,collector){
      // Return immediately if the box is empty
      var stripped;
      stripped = tube_barcode.replace(/\s*/g,'')
      if (stripped === '') {
        return;
      } else if (barcodeRegister[stripped]) {
        barcodeRegister[stripped].scanned();
      } else {
        this.tubeBarcode = stripped;
        this.monitor = collector.register();
        $('#create-tube').prop('disabled',true);
        this.addToList();
        this.validate();
      };
    }

    newScanned.prototype = {
      addToList: function() {
        $('#scanned_tube_list').append(this.newElement());
      },
      newElement: function() {
        var scanned = this;
        this.listElement =  $(document.createElement('li')).
          attr('id','listElement['+this.tubeBarcode+']').
          attr('class','wait-tube').
          attr('data-icon','delete').
          data('bed',this.tubeBarcode).
          on('click', function() { scanned.removeEntry(); }).
          append(
            $(document.createElement('a')).
            attr('href','#').append(
              $(document.createElement('h3')).
              attr('class',"ui-li-heading").
              text('Tube: '+this.tubeBarcode)
            ).append(
              $(document.createElement('div')).
              attr('class',"tube_validation_report").
              text('Waiting...')
            ).append(
              $(document.createElement('input')).
              attr('type','hidden').attr('id','tube[parents]['+this.tubeBarcode+']').attr('name','tube[parents]['+this.tubeBarcode+']').
              val(1)
            )
          );
          return this.listElement;
      },
      validate: function() {
        if (!this.barcodeRex.test(this.tubeBarcode)) { return this.barcodeError(); };
        return this.unrecognized();
      },
      unrecognized: function() {
        this.setState('bad');
        this.monitor.fail();
        this.setMessage('This tube is not part of this pool!')
        return true;
      },
      barcodeError: function() {
        this.setError("This barcode doesn't look quite right. Barcodes should be 13 digits long.");
        return false;
      },
      setError: function(message) {
        this.setState('bad');
        this.monitor.fail();
        this.setMessage(message)
      },
      setMessage: function(message) {
        this.listElement.find('.tube_validation_report').text(message)
      },
      setState: function(state) {
        for (var i = 0; i < this.states.length; i += 1) {
          if (state === this.states[i]) {
            this.listElement.addClass(this.states[i]+'-tube');
          } else {
            this.listElement.removeClass(this.states[i]+'-tube');
          }
        }
      },
      removeEntry: function() {
        this.listElement.detach();
        // This may look odd, but when we remove the tube we effectively no longer need to
        // worry about it, so can pass it.
        this.monitor.pass();
      },
      states: ['good','wait','bad'],
      barcodeRex: /^[0-9]{13}$/  // Matches stings of 13 numbers only.
    }

    tubeCollector = new statusCollector(
      function () {
        if ($('#scanned_tube_list').children().length > 0) {
          $('#tube_submit').prop('disabled',false);
        } else {
          $('#tube_submit').prop('disabled',true);
        }
      },
      function () { $('#tube_submit').prop('disabled',true); }
    );

    $('.sibling-tube').each(function(){
      new siblingTube(this,tubeCollector);
    })

    $('#tube_submit').prop('disabled',true);

    $('#tube_scan').on("keydown", function(e) {
      var code=e.charCode || e.keyCode;
      if ((code === ENTER_KEYCODE)||(code === TAB_KEYCODE)) {
        e.preventDefault();
        new newScanned(this.value,tubeCollector);
        this.value = "";
        $(this).focus();
        return false;
      }

    });

  });
})(jQuery, window);
