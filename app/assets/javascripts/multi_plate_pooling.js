(function($, exports, undefined){
  "use strict";

  $(function(event) {

    if ($('#multi-plate-pooling-page').length === 0) { return };

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
          $('#create-labware').attr('disabled', null);
        } else {
          $('#create-labware').attr('disabled', 'disabled');
        }
      }
    })

    $('.plate-box').on('change', function() {
      // When we scan in a plate
      if (this.value === "") {
        this.scanPlate();
      } else {
        this.waitPlate(); $('#create-labware').attr('disabled', 'disabled'); SCAPE.retrievePlate(this); };
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
          if (SCAPE.sourceStates.indexOf(data.plate.state) === -1) {
            this.badPlate();
          } else {
            SCAPE.plates[$(this).data('position')] = data.plate;
            this.goodPlate();
          };
          updateView();
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
              append('<div class="pool-size">'+preCapPool.length+'</div>').
              append('<div class="pool-info">'+plates[i].barcode+': '+preCapPool.join(', ')+'</div>');
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
          var barcode = SCAPE.plates[plateIndex].barcode;
          $('.plate-id-'+plateIndex).show();
          $('.plate-id-'+plateIndex+' .well').empty();
          $('.plate-id-'+plateIndex+' caption').text(barcode);
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
          seqPoolOffset += SCAPE.plates[plateIndex].preCapPools.length;
          $('#new_plate').append(newInputs);
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

    var updateView = function() {
      if (SCAPE.calculatePreCapPools()) {
        plateSummaryHandler();
        $('#pooling-summary').empty();
        renderPoolingSummary(SCAPE.plates);
        SCAPE.message('Check pooling and create plate','valid');
      } else {
        // Pooling Went wrong
        $('#pooling-summary').empty();
        SCAPE.message('Too many pools for the target plate.','invalid');
      }
    };
  });
})(jQuery,window);
