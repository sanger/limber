(function($, exports, undefined){
  "use strict";

  // Our robot controller

  $.extend(SCAPE, {
    retrievePlate : function(bed) {
      bed.ajax = $.ajax({
        dataType: "json",
        url: '/search/retrieve_parent',
        data: 'barcode='+bed.value,
        success: function(data,status) { bed.checkPlate(data,status) }
      }).fail(function(data,status) { if (status!=='abort') {bed.badPlate();} });
    }
  })

  ////////////////////////////////////////////////////////////////////
  // Custom pooling...
  $(document).on('pageinit','#custom-pooling-page',function(event) {

    SCAPE.preCapPools = function(preCapGroups, masterPlexLevel){
      var wells, failures, transfers = {}, plexLevel;

      for (var group in preCapGroups) {
        wells           = SCAPE.plate.preCapGroups[group].all_wells;
        failures        = SCAPE.plate.preCapGroups[group].failures;
        plexLevel       = SCAPE.plate.preCapGroups[group].pre_capture_plex_level
        transfers[group] = SCAPE.preCapPool(wells, failures, plexLevel);
      }

      return transfers;
    };

    SCAPE.preCapPool = function(sequencingPool, failed, plexLevel){
      plexLevel = plexLevel || 8; // To stop an infinite loop if null or 0 slips through
      var wells = [];
      for (var i =0; i < sequencingPool.length; i = i + plexLevel){
        wells.push(sequencingPool.slice(i, i + plexLevel).filter(function(w) { return failed.indexOf(w) == -1; }));
      }

      return { plexLevel: plexLevel, wells: wells };
    };

    SCAPE.newAliquot = function(poolNumber, poolID, aliquotText){
      var poolNumberInt = parseInt(poolNumber,10);

      return $(document.createElement('div')).
        addClass('aliquot colour-' + (poolNumberInt+1)).
        attr('data-pool-id', poolID).
        text(aliquotText || '\u00A0').
        hide();
    };


    var walkPreCapPools = function(preCapPools, block){
      var poolNumber = -1, seqPoolIndex = -1;
      for (var seqPoolID in preCapPools){
        seqPoolIndex++;

        for (var poolIndex in preCapPools[seqPoolID].wells){
          poolNumber++;
          block(preCapPools[seqPoolID].wells[poolIndex], poolNumber, seqPoolID, seqPoolIndex);
        }
      }
    };


    var renderPoolingSummary = function(preCapPools){

      walkPreCapPools(preCapPools, function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
        var destinationWell = SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[poolNumber];
        var listElement = $('<li/>').
          text(SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[poolNumber]).
          append('<div class="ui-li-count" data-theme="b">'+preCapPool.length+'</div>').
          append('<div class="ui-li-aside">'+preCapPool.join(', ')+'</div>');

        $('#pooling-summary').append(listElement);
      });
    };


    SCAPE.renderDestinationPools = function(){
      var preCapPools = SCAPE.plate.preCapPools;
      var well;

      $('.destination-plate .well').empty();

      $('.destination-plate .well').removeClass (function (index, css) {
        return (css.match (/\bseqPool-\d+/g) || []).join(' ');
      });

      walkPreCapPools(preCapPools, function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
        well = $('.destination-plate .' + SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[poolNumber]);


        well.addClass('seqPool-'+(seqPoolIndex+1));

        if (preCapPool.length)
          well.append(SCAPE.newAliquot(poolNumber, seqPoolID, preCapPool.length));
      });
    };


    SCAPE.renderSourceWells = function(){
      var preCapPools = SCAPE.plate.preCapPools;
      $('.source-plate .well').empty();
      $('#well-transfers').detach();

      var newInputs = $(document.createElement('div')).attr('id', 'well-transfers');

      walkPreCapPools(preCapPools,function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
        var newInput, well;

        for (var wellIndex in preCapPool){
          well = $('.source-plate .'+preCapPool[wellIndex]).addClass('seqPool-'+(seqPoolIndex+1));
          well.append( SCAPE.newAliquot(poolNumber, seqPoolID, SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[poolNumber]));

          newInput = $(document.createElement('input')).
            attr('name', 'plate[transfers]['+preCapPool[wellIndex]+']').
            attr('type', 'hidden').
            val(SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[poolNumber]);

          newInputs.append(newInput);
        }

      });

      $('.source-plate').append(newInputs);
    };

    var plateSummaryHandler = function(){
      SCAPE.renderSourceWells();
      SCAPE.renderDestinationPools();
      $('.aliquot').fadeIn('slow');
    };

    var selectSeqPoolHandler = function(event){
      SCAPE.plate.currentPool = poolIdFromLocation(
        SCAPE.plate.preCapGroups,
        $(event.currentTarget).closest('.well').data('location'));

        SCAPE.poolingSM.transitionTo('editPoolSelected');
    };

    var poolIdFromLocation = function(preCapGroups, location){
      return _.detect(
        preCapGroups,
        function(pool){ return _.contains(pool.wells, location); }
      ).id;
    };

    var highlightCurrentPool = function(){
      $('.aliquot[data-pool-id!="'+SCAPE.plate.currentPool+'"]').
        removeClass('big-aliquot selected-aliquot').
        dim();

      $('.aliquot[data-pool-id="'+SCAPE.plate.currentPool+'"]').
        css('opacity',1).
        addClass('selected-aliquot');
    };


    SCAPE.poolingSM = new SCAPE.StateMachine('.ui-content', {

      'editPool': {
        enter: function(_, delegateTarget){
          delegateTarget.on('click', '.source-plate .aliquot', selectSeqPoolHandler);

          $('.destination-plate').css('opacity',0.3);
          $('.source-plate .aliquot').addClass('big-aliquot');
        },

        leave: function(){
          $('.destination-plate').css('opacity',1);

          $('.aliquot').
            removeClass('selected-aliquot big-aliquot');
        }
      },

      'editPoolSelected': {
        enter: function(_, delegateTarget){

          delegateTarget.on('click', '.source-plate .aliquot', selectSeqPoolHandler);

          // We need to grab events on the slider for grab and release...
          var slider = $('#per-pool-plex-level').
            val(SCAPE.plate.preCapPools[SCAPE.plate.currentPool].plexLevel).
            textinput('enable').
            slider('enable').
            siblings('.ui-slider');

          delegateTarget.on('change', '#per-pool-plex-level', function(event){
            var plexLevel = parseInt($(event.currentTarget).val(), 10);

            SCAPE.plate.preCapPools[SCAPE.plate.currentPool] =
              SCAPE.preCapPool(SCAPE.plate.preCapGroups[SCAPE.plate.currentPool].all_wells, SCAPE.plate.preCapGroups[SCAPE.plate.currentPool].failures, plexLevel );

            SCAPE.renderSourceWells();
            SCAPE.renderDestinationPools();

            highlightCurrentPool();
            $('.aliquot').fadeIn('slow');
          });


          highlightCurrentPool();
        },

        leave: function(){
          $('.aliquot').css('opacity', 1).removeClass('selected-aliquot');
          $('#per-pool-plex-level').textinput('disable').slider('disable').val('');
          SCAPE.plate.currentPool = undefined;
        }
      },

      'poolingSummary': {
        enter: function(){
          plateSummaryHandler();
          renderPoolingSummary(SCAPE.plate.preCapPools);
          $('.create-button').prop('disabled',false);
        },

        leave: function(){
          $('#pooling-summary').empty();
          $('.create-button').prop('disabled',true);
        }
      }
    });

    SCAPE.linkCallbacks.add(SCAPE.poolingSM.transitionLink);
    // Calculate the pools and render the plate
    SCAPE.plate.preCapPools = SCAPE.preCapPools( SCAPE.plate.preCapGroups, null );
    SCAPE.poolingSM.transitionTo('poolingSummary');

    $('.create-button').prop('disabled',false);
  });

  ////////////////////////////////////////////////////////////////////
  // Multi Plate Custom pooling...
  $(document).on('pageinit','#multi-plate-pooling-page',function(event) {

    $.extend(SCAPE, {
      retrievePlate : function(plate) {
        plate.ajax = $.ajax({
          dataType: "json",
          url: '/search/',
          type: 'POST',
          data: 'plate_barcode='+plate.value,
          success: function(data,status) { plate.checkPlate(data,status); }
        }).fail(function(data,status) { if (status!=='abort') { plate.badPlate(); } });
      },
      checkPlates : function() {
        if ($('.wait-plate, .bad-plate').size() === 0) {
          $('#summary_tab').removeClass('ui-disabled');
        } else {
          $('#summary_tab').addClass('ui-disabled');
        }
      }
    })

    $('.plate-box').on('change', function() {
      // When we scan in a plate
      if (this.value === "") {
        this.scanPlate();
      } else {
        this.waitPlate(); $('#summary_tab').addClass('ui-disabled'); SCAPE.retrievePlate(this); };
    });

    $('.plate-box').each(function(){

      $.extend(this, {
        /*
          Our plate beds
        */
        waitPlate : function() {
          this.clearPlate();
          $(this).closest('.plate-container').removeClass('good-plate bad-plate scan-plate');
          $(this).closest('.plate-container').addClass('wait-plate');
          $('#summary_tab').addClass('ui-disabled');
        },
        scanPlate : function() {
          this.clearPlate();
          $(this).closest('.plate-container').removeClass('good-plate wait-plate bad-plate');
          $(this).closest('.plate-container').addClass('scan-plate');
          SCAPE.checkPlates();
        },
        badPlate : function() {
          this.clearPlate();
          $(this).closest('.plate-container').removeClass('good-plate wait-plate scan-plate');
          $(this).closest('.plate-container').addClass('bad-plate');
          $('#summary_tab').addClass('ui-disabled');
        },
        goodPlate : function() {
          $(this).closest('.plate-container').removeClass('bad-plate wait-plate scan-plate');
          $(this).closest('.plate-container').addClass('good-plate');
          SCAPE.checkPlates();
        },
        checkPlate : function(data,status) {
          if (data.plate.state===SCAPE.sourceState && data.plate.purpose==SCAPE.sourcePurpose) {
            SCAPE.plates[$(this).data('position')] = data.plate;
            this.goodPlate();
          } else {
            this.badPlate();
          }
        },
        clearPlate : function() {
          SCAPE.plates[$(this).data('position')] = undefined;
        }
      })

    })

    SCAPE.totalPools = function() {
      var poolCount = 0;
      for (var plateIndex = 0; plateIndex < SCAPE.plates.length; plateIndex += 1) {
        if (SCAPE.plates[plateIndex]!==undefined) {
          var preCapPools = SCAPE.plates[plateIndex].preCapPools;
          poolCount += walkPreCapPools(preCapPools, function(){});
        }
      }
      return poolCount;
    }

    SCAPE.calculatePreCapPools = function() {
      for (var plateIndex in SCAPE.plates){
            var plate = SCAPE.plates[plateIndex];
            if (plate!==undefined) { SCAPE.plates[plateIndex].preCapPools = SCAPE.preCapPools( SCAPE.plates[plateIndex] )}
          }
      return SCAPE.totalPools() <= 96
    };

    SCAPE.preCapPools = function(plate){
      var wells, failures, transfers = {}, plexLevel;

      for (var group in plate.preCapGroups) {
        wells           = plate.preCapGroups[group].all_wells;
        failures        = plate.preCapGroups[group].failures;
        plexLevel       = plate.preCapGroups[group].pre_capture_plex_level
        transfers[group] = SCAPE.preCapPool(wells, failures, plexLevel);
      }

      return transfers;
    };

    SCAPE.preCapPool = function(sequencingPool, failed, plexLevel){
      plexLevel = plexLevel || 8; // To stop an infinite loop if null or 0 slips through
      var wells = [];
      for (var i =0; i < sequencingPool.length; i = i + plexLevel){
        wells.push(sequencingPool.slice(i, i + plexLevel).filter(function(w) { return failed.indexOf(w) == -1; }));
      }

      return { plexLevel: plexLevel, wells: wells };
    };

    SCAPE.newAliquot = function(poolNumber, poolID, aliquotText){
      var poolNumberInt = parseInt(poolNumber,10);

      return $(document.createElement('div')).
        addClass('aliquot colour-' + (poolNumberInt+1)).
        attr('data-pool-id', poolID).
        text(aliquotText || '\u00A0').
        hide();
    };


    var walkPreCapPools = function(preCapPools, block){
      var poolNumber = -1, seqPoolIndex = -1;
      for (var seqPoolID in preCapPools){
        seqPoolIndex++;

        for (var poolIndex in preCapPools[seqPoolID].wells){
          poolNumber++;
          block(preCapPools[seqPoolID].wells[poolIndex], poolNumber, seqPoolID, seqPoolIndex);
        }
      }
      return poolNumber+1;
    };


    var renderPoolingSummary = function(plates){
      var capPoolOffset = 0;

      for (var i in plates) {
        if (plates[i]===undefined) {
        } else {
          var preCapPools = plates[i].preCapPools
          capPoolOffset += walkPreCapPools(preCapPools, function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
            var destinationWell = SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber];
            var listElement = $('<li/>').
              text(SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]).
              append('<div class="ui-li-count" data-theme="b">'+preCapPool.length+'</div>').
              append('<div class="ui-li-aside">'+plates[i].barcode+': '+preCapPool.join(', ')+'</div>');
            $('#pooling-summary').append(listElement);
          });
        };
      };
    };

    SCAPE.renderDestinationPools = function(){

      $('.destination-plate .well').empty();
      $('.destination-plate .well').removeClass (function (index, css) {
        return (css.match (/\bseqPool-\d+/g) || []).join(' ');
      });

      var capPoolOffset = 0;
      var seqPoolOffset = 0;
      for (var plateIndex = 0; plateIndex < SCAPE.plates.length; plateIndex += 1) {
        if (SCAPE.plates[plateIndex]!==undefined) {
          var preCapPools = SCAPE.plates[plateIndex].preCapPools;
          var well;
          capPoolOffset += walkPreCapPools(preCapPools, function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
            well = $('.destination-plate .' + SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]);
            well.addClass('seqPool-'+(seqPoolOffset+seqPoolIndex+1));
            if (preCapPool.length)
              well.append(SCAPE.newAliquot(capPoolOffset+poolNumber, seqPoolID, preCapPool.length));
          });
        for (var i in SCAPE.plates[0].preCapPools) { seqPoolOffset +=1 };
        }
      }
    };


    SCAPE.renderSourceWells = function(){
      var capPoolOffset = 0;
      var seqPoolOffset = 0;
      var map = {};
      for (var plateIndex = 0; plateIndex < SCAPE.plates.length; plateIndex += 1) {
        if (SCAPE.plates[plateIndex]===undefined) {
          $('.plate-id-'+plateIndex).hide();
        } else {

          var preCapPools = SCAPE.plates[plateIndex].preCapPools;
          $('.plate-id-'+plateIndex).show();
          $('.plate-id-'+plateIndex+' .well').empty();
          $('#well-transfers-'+plateIndex).detach();

          var newInputs = $(document.createElement('div')).attr('id', 'well-transfers-'+plateIndex);
          capPoolOffset += walkPreCapPools(preCapPools,function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
            var newInput, well;

            for (var wellIndex in preCapPool){
              well = $('.plate-id-'+plateIndex+' .'+preCapPool[wellIndex]).addClass('seqPool-'+(seqPoolOffset+seqPoolIndex+1));
              well.append( SCAPE.newAliquot(capPoolOffset+poolNumber, seqPoolID, SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]));

              newInput = $(document.createElement('input')).
                attr('name', 'plate[transfers]['+SCAPE.plates[plateIndex].uuid+']['+preCapPool[wellIndex]+']').
                attr('type', 'hidden').
                val(SCAPE.WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]);

              newInputs.append(newInput);
            }
          });
          for (var i in SCAPE.plates[0].preCapPools) { seqPoolOffset +=1 };
          $('.plate-id-'+plateIndex).append(newInputs);
        }
      }
    };

    var plateSummaryHandler = function(){

      SCAPE.renderSourceWells();
      SCAPE.renderDestinationPools();

      $('.aliquot').fadeIn('slow');

      $('.well').each(function(){

        if ($(this).children().length < 2) { return; }

        this.pos = 0;

        this.slide = function() {
          var scrollTo
          this.pos = (this.pos + 1) % $(this).children().length;
          scrollTo = $(this).children()[this.pos].offsetTop-5;
          $(this).delay(1000).animate({scrollTop:scrollTo},500,this.slide)
        };
        this.slide();
      })
    };

    SCAPE.poolingSM = new SCAPE.StateMachine('.ui-content', {

      'addPlates' :{
        enter: function(){
          $('.create-button').prop('disabled',true);
        },

        leave: function(){
          // validatePlates();
        }
      },

      'poolingSummary': {
        enter: function(){
          if (SCAPE.calculatePreCapPools()) {
            plateSummaryHandler();
            $('#pooling-summary').empty();
            renderPoolingSummary(SCAPE.plates);
            $('.create-button').prop('disabled',false);
            SCAPE.message('Check pooling and create plate','valid');
          } else {
            // Pooling Went wrong
            $('#pooling-summary').empty();
            $('.create-button').prop('disabled',true);
            SCAPE.message('Too many pools for the target plate.','invalid');
          }
        },

        leave: function(){
          $('#pooling-summary').empty();
          $('.create-button').prop('disabled',true);
        }
      }
    });

    SCAPE.linkCallbacks.add(SCAPE.poolingSM.transitionLink);
    SCAPE.poolingSM.transitionTo('addPlates');

  });
})(jQuery,window);
