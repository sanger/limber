(function($, exports, undefined){
  "use strict";
  // Declared as var  rather than const due to issues with const in strict mode
  // in the older versions of Chrome (34) used in the labs.
  var WELLS_IN_COLUMN_MAJOR_ORDER = [
    'A1',  'B1',  'C1',  'D1',  'E1',  'F1',  'G1',  'H1',
    'A2',  'B2',  'C2',  'D2',  'E2',  'F2',  'G2',  'H2',
    'A3',  'B3',  'C3',  'D3',  'E3',  'F3',  'G3',  'H3',
    'A4',  'B4',  'C4',  'D4',  'E4',  'F4',  'G4',  'H4',
    'A5',  'B5',  'C5',  'D5',  'E5',  'F5',  'G5',  'H5',
    'A6',  'B6',  'C6',  'D6',  'E6',  'F6',  'G6',  'H6',
    'A7',  'B7',  'C7',  'D7',  'E7',  'F7',  'G7',  'H7',
    'A8',  'B8',  'C8',  'D8',  'E8',  'F8',  'G8',  'H8',
    'A9',  'B9',  'C9',  'D9',  'E9',  'F9',  'G9',  'H9',
    'A10', 'B10', 'C10', 'D10', 'E10', 'F10', 'G10', 'H10',
    'A11', 'B11', 'C11', 'D11', 'E11', 'F11', 'G11', 'H11',
    'A12', 'B12', 'C12', 'D12', 'E12', 'F12', 'G12', 'H12'
  ]

  // Declared as var  rather than const due to issues with const in strict mode
  // in the older versions of Chrome (34) used in the labs.
  var SOURCE_STATES = ['passed', 'qc_complete']

  $(function(_event) {

    if ($('#multi-plate-pooling-page').length === 0) { return };

    $.extend(SCAPE, {
      retrievePlate : function(plate) {
        plate.ajax = $.ajax({
          dataType: 'json',
          url: '/search/',
          type: 'POST',
          data: 'plate_barcode='+plate.value,
          success: function(data,status) { plate.checkPlate(data,status); }
        }).fail(function(data,status) { if (status!=='abort') { plate.badPlate(); } });
      },
      checkPlates : function() {
        if ($('.wait-plate, .bad-plate').length === 0) {
          $('#create-labware').attr('disabled', null);
        } else {
          $('#create-labware').attr('disabled', 'disabled');
        }
      },
      plate: {},
      plates: []
    })

    $('.plate-box').on('change', function() {
      // When we scan in a plate
      if (this.value === '') {
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
          if (SOURCE_STATES.indexOf(data.plate.state) === -1) {
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
      var wells, failures, transfers = {};

      for (var group in plate.preCapGroups) {
        wells           = plate.preCapGroups[group].all_wells;
        failures        = plate.preCapGroups[group].failures;
        transfers[group] = SCAPE.preCapPool(wells, failures);
      }

      return transfers;
    };

    SCAPE.preCapPool = function(sequencingPool, failed){
      var wells = [];
      wells.push(sequencingPool.filter(function(w) { return failed.indexOf(w) == -1; }));

      return { wells: wells };
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
          // Nothing
        } else {
          var preCapPools = plates[i].preCapPools
          capPoolOffset += walkPreCapPools(preCapPools, function(preCapPool, poolNumber, seqPoolID, seqPoolIndex){
            var destinationWell = WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber];
            var listElement = $('<li/>').
              text(WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]).
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
            well = $('.destination-plate .' + WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]);
            well.addClass('seqPool-'+(seqPoolOffset+seqPoolIndex+1));
            if (preCapPool.length)
              well.append(SCAPE.newAliquot(capPoolOffset+poolNumber, seqPoolID, preCapPool.length));
          });
        for (var i in SCAPE.plates[plateIndex].preCapPools) { seqPoolOffset +=1 };
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
              well.append( SCAPE.newAliquot(capPoolOffset+poolNumber, seqPoolID, WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]));

              newInput = $(document.createElement('input')).
                attr('name', 'plate[transfers]['+SCAPE.plates[plateIndex].uuid+']['+preCapPool[wellIndex]+']').
                attr('type', 'hidden').
                val(WELLS_IN_COLUMN_MAJOR_ORDER[capPoolOffset+poolNumber]);

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
