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
})(jQuery,window);
