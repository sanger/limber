(function($, exports, undefined){
  "use strict";

  var ENTER_KEYCODE = 13, TAB_KEYCODE = 9;

  // Set up the SCAPE namespace
  if (exports.SCAPE === undefined) {
    exports.SCAPE = {};
  }

  $.extend($, {
    cssToCamel: function(string) {
      return string.replace(/-([a-z])/gi, function(s, group1) {
        return group1.toUpperCase();
      });
    }
  });


  $.extend(SCAPE, {
  //temporarily used until page ready event sorted... :(
  //This is a copy of the template held in the tagging page.
  tag_palette_template:
    '<li class="ui-li ui-li-static ui-body-c">'+
    '<div class="available-tag palette-tag"><%= tag_id %></div>&nbsp;&nbsp;Tag <%= tag_id %>'+
    '</li>',

  //temporarily used until page ready event sorted... :(
  //This is a copy of the template held in the tagging page.
  substitution_tag_template:
    '<li class="ui-li ui-li-static ui-body-c" data-split-icon="delete">'+
    '<div class="substitute-tag palette-tag"><%= original_tag_id %></div>&nbsp;&nbsp;Tag <%= original_tag_id %> replaced with Tag <%= replacement_tag_id %>&nbsp;&nbsp;<div class="available-tag palette-tag"><%= replacement_tag_id %></div>'+
    '<input id="plate-substitutions-<%= original_tag_id %>" name="plate[substitutions][<%= original_tag_id %>]" type="hidden" value="<%= replacement_tag_id %>" />'+
    '</li>',
  animateWell: function() {
    if ($(this).children().length < 2) { return; }
    this.pos = 0;
    this.slide = function() {
      var scrollTo;
      this.pos = (this.pos + 1) % $(this).children().length;
      scrollTo = $(this).children()[this.pos].offsetTop-5;
      $(this).delay(1000).animate({scrollTop:scrollTo},500,this.slide)
    };
    this.slide();
  },

  dim: function() {
    $(this).fadeTo('fast', 0.2);
    return this;
  },

    WELLS_IN_COLUMN_MAJOR_ORDER: [
      "A1",  "B1",  "C1",  "D1",  "E1",  "F1",  "G1",  "H1",
      "A2",  "B2",  "C2",  "D2",  "E2",  "F2",  "G2",  "H2",
      "A3",  "B3",  "C3",  "D3",  "E3",  "F3",  "G3",  "H3",
      "A4",  "B4",  "C4",  "D4",  "E4",  "F4",  "G4",  "H4",
      "A5",  "B5",  "C5",  "D5",  "E5",  "F5",  "G5",  "H5",
      "A6",  "B6",  "C6",  "D6",  "E6",  "F6",  "G6",  "H6",
      "A7",  "B7",  "C7",  "D7",  "E7",  "F7",  "G7",  "H7",
      "A8",  "B8",  "C8",  "D8",  "E8",  "F8",  "G8",  "H8",
      "A9",  "B9",  "C9",  "D9",  "E9",  "F9",  "G9",  "H9",
      "A10", "B10", "C10", "D10", "E10", "F10", "G10", "H10",
      "A11", "B11", "C11", "D11", "E11", "F11", "G11", "H11",
      "A12", "B12", "C12", "D12", "E12", "F12", "G12", "H12"
    ],


    linkCallbacks: $.Callbacks(),

    linkHandler: function(event){
      var targetTab  = $(event.currentTarget).attr('rel');
      var targetIds  = '#'+SCAPE.plate.tabViews[targetTab].join(', #');
      var nonTargets = $('.scape-ui-block').not(targetIds);

      nonTargets.fadeOut();
      nonTargets.promise().done(function(){ $(targetIds).fadeIn(); });
    },


    StateMachine: function(delegateTarget, states){
      var sm             = this;
      var stateNames     = _.keys(states);
      var stateCallbacks = {};
      sm.delegateTarget  = $(delegateTarget);

      var beforeCallback = function(event){
        sm.delegateTarget.off();
      };


      var afterCallback = function(newState){
        sm.currentState = newState;
      };


      var callbacks, otherStates;
      for (var stateName in states){
        otherStates = _.difference(stateNames, [stateName]);
        callbacks = [
          beforeCallback,
          states[stateName].enter
        ];

        callbacks = callbacks.concat(otherStates.map(
          function(otherStateName){
            return function(){
              if(sm.currentState === otherStateName)
              return states[otherStateName].leave();
            };
        }
        ));

        callbacks = _.compact(callbacks).concat(afterCallback);

        stateCallbacks[stateName] = $.Callbacks().add(callbacks);
      }


      sm.transitionTo = function(newState){
        if (stateCallbacks[newState] === undefined) throw "Unknown State: " + newState;

        stateCallbacks[newState].fire(newState, sm.delegateTarget);
      };


      sm.transitionLink = function(e){
        var newState = $.cssToCamel($(e.currentTarget).attr('rel'));
        sm.transitionTo(newState);
      };
    },


  failWellToggleHandler:  function(event){
    $(event.currentTarget).hide('fast', function(){
      var failing = $(event.currentTarget).toggleClass('good failed').show().hasClass('failed');
      $(event.currentTarget).find('input:hidden')[failing ? 'attr' : 'removeAttr']('checked', 'checked');
    });
  },


  PlateViewModel: function(plate, plateElement, control) {
    // Using the 'that' pattern...
    // ...'that' refers to the object created by this constructor.
    // ...'this' used in any of the functions will be set at runtime.
    var that          = this;
    that.plate        = plate;
    that.plateElement = plateElement;
    that.control      = control;


    that.statusColour = function() {
      that.plateElement.find('.aliquot').
        addClass(that.plate.state);
    };

    that.well_index_by_row = function(well){
      var row, col
      row = well.charCodeAt(0)-65;
      col = parseInt(well.slice(1));
      return (row*12)+col
    };

    that.poolsArray = function(){
      var poolsArray = _.toArray(that.plate.pools);
      poolsArray = _.sortBy(poolsArray, function(pool){
        return that.well_index_by_row(pool.wells[0]);
      });

      return poolsArray;
    }();

    that.colourPools = function() {

      for (var i=0; i < that.poolsArray.length; i++){
        var poolId = that.poolsArray[i].id;

        that.plateElement.find('.aliquot[data-pool='+poolId+']').
          addClass('colour-'+(i+1));
      }

    };

    that.clearAliquotSelection = function(){
      that.plateElement.
        find('.aliquot').
        removeClass('selected-aliquot dimmed');
    };

    that['summary-view'] = {
      activate: function(){
          $('#summary-information').fadeIn('fast');
          that.statusColour();
          that.colourPools();

      },

      deactivate: function(){
        $('#summary-information').hide();
      }
    };

    that['pools-view'] = {
      activate: function(){
        $('#pools-information').fadeIn('fast');

        $('#pools-information li').fadeIn('fast');

        that.plateElement.find('.aliquot').
          removeClass(that.plate.state).
          removeClass('selected-aliquot dimmed');

        that.colourPools();

        that.control.find('a[data-plate-view="pools-view"]').tab('show')
      },

      deactivate: function(){
        $('#pools-information').hide(function(){
          $('#pools-information li').
            removeClass('dimmed');

          that.plateElement.
            find('.aliquot').
            removeClass('selected-aliquot dimmed');

        });
      }
    };

    that['samples-view'] = {
      activate: function(){
          $('#samples-information').fadeIn('fast');
          that.statusColour();
      },

      deactivate: function(){
        $('#samples-information').hide();
      }

    };


    that.sm = new StateMachine;
    that.sm.add(that['summary-view']);
    that.sm.add(that['pools-view']);
    that.sm.add(that['samples-view']);

    that['summary-view'].active();
  },


  limberPlateView: function(plate) {
    var plateElement = $(this);

    var control = $('#plate-view-control');

    var viewModel = new SCAPE.PlateViewModel(plate, plateElement, control);

    $('#plate-view-control a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      var viewName = e.target.dataset.plateView;
      viewModel[viewName].active();
    })

    control.on('change', 'input:radio', function(event){
      var viewName = $(event.currentTarget).val();
      viewModel[viewName].active();
    });

    plateElement.on('click', '.aliquot', function(event) {
      var pool = $(event.currentTarget).data('pool');

      viewModel['pools-view'].active();

      plateElement.
        find('.aliquot[data-pool!='+pool+']').
        removeClass('selected-aliquot').addClass('dimmed');

      plateElement.
        find('.aliquot[data-pool='+pool+']').
        addClass('selected-aliquot').
        removeClass('dimmed');

        $('#pools-information li[data-pool!='+pool+']').
          fadeOut('fast').
          promise().
          done(function(){
            $('#pools-information li[data-pool='+pool+']').fadeIn('fast');
        });



    });

    // ...we will never break the chain...
    return this;
  }

  });

  // Extend jQuery prototype...
  $.extend($.fn, {
    limberPlateView:    SCAPE.limberPlateView,
    dim:                SCAPE.dim
  });


  // ########################################################################
  // # Page events....
  $(document).on('pageinit', function(){
    // Trap the carriage return sent by the swipecard reader
    $(document).on("keydown", "input.card-id", function(e) {
      var code=e.charCode || e.keyCode;
      if ((code === ENTER_KEYCODE)||(code === TAB_KEYCODE)) {
        $('input[data-type="search"], .plate-barcode').last().focus();
        return false;
      }

    });

    var myPlateButtonObserver = function(event){
      if ($(event.currentTarget).val()) {
          $('.show-my-plates-button').prop('disabled',true);
      } else if ($('input.card-id').val()) {
          $('.show-my-plates-button').prop('disabled',false);
      }
    };

    $(document).on("keyup", ".plate-barcode", myPlateButtonObserver);
    $(document).on("keyup", ".card-id", myPlateButtonObserver);

    // Trap the carriage return sent by barcode scanner
    $(document).on("keydown", ".plate-barcode", function(event) {
      var code=event.charCode || event.keyCode;
      // Check for carrage return (key code ENTER_KEYCODE)
      if ((code === ENTER_KEYCODE)||(code === TAB_KEYCODE)) {
        // Check that the value is 13 characters long like a barcode
        if ($(event.currentTarget).val().length === 13) {
          $(event.currentTarget).closest('form').find('.show-my-plates').val(false);
          $(event.currentTarget).closest('.plate-search-form').submit();
        }
      }
    });

    if ($('input.card-id').val()) {
      $('.ui-header').removeClass('ui-bar-a').addClass('ui-bar-b');
    }

    // Change the colour of the title bar to show a user id
    $(document).on('blur', 'input.card-id', function(event){
      if ($(event.currentTarget).val()) {
        $('.ui-header').removeClass('ui-bar-a').addClass('ui-bar-b');
      } else {
        $('.ui-header').removeClass('ui-bar-b').addClass('ui-bar-a');
      }
    });


    // Fill in the plate barcode with the plate links barcode
    $(document).on('click', ".plate-link", function(event) {
      $('.plate-barcode').val($(event.currentTarget).attr('id').substr(6));
      $('.show-my-plates').val(false);
      $('.plate-search-form').submit();
      return false;
    });


    // Disable submit buttons after first click...
    $(document).on('submit', 'form', function(event){
      $(event.currentTarget).find(':submit').
        button('disable').
        prev('.ui-btn-inner').
        find('.ui-btn-text').
        text('Working...');

      return true;
    });

  });

  $(document).bind('pageshow', function() {
    $($('.ui-page-active form :input:visible')[0]).focus();
  });

  $(function(event) {
    // Set up the plate element as an illuminaBPlate...
    if ($('#plate-show-page').length === 0) { return };
    $('#plate').limberPlateView(SCAPE.labware);
  });

  $(document).on('pageinit', function(){
    SCAPE.linkCallbacks.add(SCAPE.linkHandler);

    $(document).on('click','.navbar-link', SCAPE.linkCallbacks.fire);
  });

  // A status collector can have monitors registered. It will trigger
  // its onSuccess event when all monitors are true, and its onRevert
  // event if any are false.
  var statusCollector = function(onSuccess,onRevert) {
    // Fires when all guards are true
    this.onSuccess =  onSuccess;
    // Fires if a guard is invalidated
    this.onRevert  = onRevert;
    this.monitors  = [];
  };

  // Monitors are registered to a collector. When the change state they
  // trigger the collector to check the state of all its monitors.
  var monitor = function(state,collector) {
    this.valid     = state||false;
    this.collector = collector;
  }

  monitor.prototype = {
    pass: function () {
      this.valid = true;
      this.collector.collate();
    },
    fail: function () {
      this.valid = false;
      this.collector.collate();
    }
  }

  statusCollector.prototype = {
    register: function (status) {
      var new_monitor = new monitor(status,this);
      this.monitors.push(new_monitor)
      return new_monitor;
    },
    collate: function () {
      for (var i =0; i < this.monitors.length; i+=1) {
        if (!this.monitors[i].valid) { return this.onRevert(); }
      }
      return this.onSuccess();
    }
  }

  ////////////////////////////////////////////////////////////////////
  // Tube Pooling page
  $(document).on('pageinit','#multi-tube-pooling-page',function(event) {

    var newScanned, tubeCollector, siblingTube, barcodeRegister = {}

    $.ajaxSetup({
      beforeSend: function(xhr) {
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
    });

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
