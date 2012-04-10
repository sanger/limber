(function(window, $, undefined){
  "use strict";

  // Set up the SCAPE namespace
  if (window.SCAPE === undefined) {
    window.SCAPE = {};
  }

  //temporarily used until page ready event sorted... :(
  //This is a copy of the template held in the tagging page.
  SCAPE.tag_palette_template =
    '<li class="ui-li ui-li-static ui-body-c">'+
    '<div class="available-tag palette-tag"><%= tag_id %></div>&nbsp;&nbsp;Tag <%= tag_id %>'+
    '</li>';

  //temporarily used until page ready event sorted... :(
  //This is a copy of the template held in the tagging page.
  SCAPE.substitution_tag_template =
    '<li class="ui-li ui-li-static ui-body-c" data-split-icon="delete">'+
    '<div class="substitute-tag palette-tag"><%= original_tag_id %></div>&nbsp;&nbsp;Tag <%= original_tag_id %> replaced with Tag <%= replacement_tag_id %>&nbsp;&nbsp;<div class="available-tag palette-tag"><%= replacement_tag_id %></div>'+
    '<input id="plate-substitutions-<%= original_tag_id %>" name="plate[substitutions][<%= original_tag_id %>]" type="hidden" value="<%= replacement_tag_id %>" />'+
    '</li>';

  SCAPE.displayReason = function() {
    if($('.reason:visible').length === 0) {
      $('#'+$('#state option:selected').val()).slideDown('slow').find('select:disabled').removeAttr('disabled');
    } 
    else {
      $('.reason').not('#'+$('#state option:selected').val()).slideUp('slow', function(){
        $('#'+$('#state option:selected').val()).slideDown('slow').find('select:disabled').removeAttr('disabled');
      });
    }

  };

  SCAPE.dim = function() { $(this).fadeTo('fast', 0.2); };

  // Extend jQuery...
  $.extend({
    createElement: function(elementName){
      return $(document.createElement(elementName));
    }
  });


  // ########################################################################
  // # Page events....
  $('#search-page').live('pageinit', function(event){
    // Users should start the page by scanning in...
    $('#card_id').focus();

    $('#card_id').live('blur', function(){
      if ($(this).val()) {
        $('.ui-header').removeClass('ui-bar-a').addClass('ui-bar-b');
      } else {
        $('.ui-header').removeClass('ui-bar-b').addClass('ui-bar-a');
      }
    });

    // Trap the carriage return sent by the swipecard reader
    $("#card_id").live("keydown", function(e) {
      var code=e.charCode || e.keyCode;
      if (code==13) {
        $("#plate_barcode").focus();
        return false;
      }
    });

    // Fill in the plate barcode with the plate links barcode
    $(".plate_link").click(function() {
      $('#plate_barcode').val($(this).attr('id').substr(6));
      $('#plate-search-form').submit();
      return false;
    });

  });


  $('#plate-show-page').live('pagecreate', function(event) {

    var tabsForState = '#'+SCAPE.plate.tabStates[SCAPE.plate.state].join(', #');

    $('#navbar li').not(tabsForState).remove();
    $('#'+SCAPE.plate.tabStates[SCAPE.plate.state][0]).find('a').addClass('ui-btn-active');


    SCAPE.linkHandler = function(){
      var targetTab = $(this).attr('rel');
      var targetIds = '#'+SCAPE.plate.tabViews[targetTab].join(', #');

      $('.scape-ui-block').
        not(targetIds).
        filter(':visible').
        fadeOut( function(){ $(targetIds).fadeIn(); } );
    };

    $('.navbar-link').live('click', SCAPE.linkHandler);
  });

  $('#plate-show-page').live('pageinit', function(event){
    var targetTab = SCAPE.plate.tabStates[SCAPE.plate.state][0];
    var targetIds = '#'+SCAPE.plate.tabViews[targetTab].join(', #');

    $(targetIds).not(':visible').fadeIn();

    $('#well-failing .plate-view .aliquot').
      not('.permanent-failure').
      toggle(
        function(){
      $(this).hide('fast', function(){
        var failing = $(this).toggleClass('good failed').show().hasClass('failed');
        $(this).find('input:hidden')[failing ? 'attr' : 'removeAttr']('checked', 'checked');
      });
    },

    function() {
      $(this).hide('fast', function(){
        var failing = $(this).toggleClass('failed good').show().hasClass('failed');
        $(this).find('input:hidden')[failing ? 'attr' : 'removeAttr']('checked', 'checked');
      });
    }
    );

    // State changes reasons...
    SCAPE.displayReason();
    $('#state').live('change', SCAPE.displayReason);
  });


  $('#admin-page').live('pageinit',function(event) {

    $('#plate_edit').submit(function() {
      if ($('#card_id').val().length === 0) {
        alert("Please scan your swipecard...");
        return false;
      }
    });

    // Trap the carriage return sent by the swipecard reader
    $("#card_id").live("keydown", function(e) {
      var code=e.charCode || e.keyCode;
      if (code==13) return false;
    });

    SCAPE.displayReason();
    $('#state').live('click',SCAPE.displayReason);
  });

  $('#creation-page').live('pageinit',function(event) {
    var transfers = {
      'Transfer columns 1-1':  '.col-1',
      'Transfer columns 1-2':  '.col-1,.col-2',
      'Transfer columns 1-3':  '.col-1,.col-2,.col-3',
      'Transfer columns 1-4':  '.col-1,.col-2,.col-3,.col-4',
      'Transfer columns 1-6':  '.col-1,.col-2,.col-3,.col-4,.col-5,.col-6',
      'Transfer columns 1-12': '.col-all'
    };

    function template_display(){
      var selectedColumns = transfers[$('#plate_transfer_template_uuid option:selected').text()];
      var aliquots = $('#transfer-plate .aliquot');
      aliquots.not(selectedColumns).hide('slow');
      aliquots.filter(selectedColumns).show('slow');
    }

    $('#plate_transfer_template_uuid').change(template_display);
  });


  $('#tag-creation-page').live('pageinit', function(){

    $.extend(window.SCAPE, {

      tagpaletteTemplate     : _.template(SCAPE.tag_palette_template),
      substitutionTemplate  : _.template(SCAPE.substitution_tag_template),

      updateTagpalette  : function() {
        var tagpalette = $('#tag-palette');

        tagpalette.empty();

        var currentTagGroup   = $(window.tags_by_name[$('#plate_tag_layout_template_uuid option:selected').text()]);
        var currentlyUsedTags = $('.aliquot').map(function(){ return parseInt($(this).text(), 10); });
        var unusedTags        = _.difference(currentTagGroup, currentlyUsedTags);
        var listItems         = unusedTags.reduce(
          function(memo, tagId) { return memo + SCAPE.tagpaletteTemplate({tag_id: tagId}); }, '<li data-role="list-divider" class="ui-li ui-li-divider ui-btn ui-bar-b ui-corner-top ui-btn-up-undefined">Replacement Tags</li>');

          tagpalette.append(listItems);
          $('#tag-palette li:last').addClass('ui-li ui-li-static ui-body-c ui-corner-bottom');

      },

      tagSubstitutionHandler : function() {
        var sourceAliquot = $(this);
        var originalTag   = sourceAliquot.text();

        // Dim other tags...
        $('.aliquot').not('.tag-'+originalTag).each(SCAPE.dim);

        SCAPE.updateTagpalette();

        // Show the tag palette...
        $('#instructions').fadeOut(function(){
          $('#replacement-tags').fadeIn();
        });


        function paletteTagHandler() {
          var newTag = $(this).text();

          // Find all the aliquots using the original tag
          // swap their tag classes and text
          $('.aliquot.tag-'+originalTag).
            hide().
            removeClass('tag-'+originalTag).
            addClass('tag-'+newTag).
            text(newTag).
            addClass('selected-aliquot').
            show('fast');

          // Add the substitution as a hidden field and li
          $('#substitutions ul').append(SCAPE.substitutionTemplate({original_tag_id: originalTag, replacement_tag_id: newTag}));
          $('#substitutions ul').listview('refresh');

          SCAPE.resetHandler();
        }
        // Remove old behaviour and add the new to available-tags
        $('.available-tag').unbind().click(paletteTagHandler);

      },


      update_layout : function () {
        var tags = $(window.tag_layouts[$('#plate_tag_layout_template_uuid option:selected').text()]);

        tags.each(function(index) {
          $('#tagging-plate #aliquot_'+this[0]).
            hide('slow').text(this[1][1]).
            addClass('aliquot colour-'+this[1][0]).
            addClass('tag-'+this[1][1]).
            show('slow');
        });

        SCAPE.resetHandler();
        SCAPE.resetSubstitutions();
      },

      resetSubstitutions : function() {
        $('#substitutions ul').empty();
        $('#tagging-plate .aliquot').removeClass('selected-aliquot');
      },

      resetHandler : function() {
        $('.aliquot').css('opacity', 1);
        $('.available-tags').unbind();
        $('#replacement-tags').fadeOut(function(){
          $('#instructions').fadeIn();
        });
      }

    });


    $('#tagging-plate .aliquot').removeClass('green orange red');

    SCAPE.update_layout();
    $('#plate_tag_layout_template_uuid').change(SCAPE.update_layout);
    $('#tagging-plate .aliquot').toggle(SCAPE.tagSubstitutionHandler, SCAPE.resetHandler);

  });

  $('#custom-pooling-page').live('pageinit',function(event) {
    var sourceWell        = undefined;
    var destinationWell   = undefined;

     var undimAliquots = function(){
      $('.well, .aliquot').css('opacity', '1.0');
    };

    var setPoolingValue = function(sourceWell, destinationWell) {
      var destination        = getLocation(destinationWell);
      var oldDestination     = getLocation(sourceWell);
      var oldDestinationWell = $('#destination_plate .well[data-location    = ' + oldDestination + ']');

      sourceWell.find('.aliquot').
        text(destination).
        addClass('aliquot source_aliquot ' + coloursByLocation[destination]).
        attr('data-destination-well', destination);

      sourceWell.find('input').val(destination);

      addAliquot(destinationWell);

      resetAliquotCounts();

      $('#destination_plate .well[data-aliquot-count=0]').children().remove();

      // setupHighLightTransfers();
    };

    function resetAliquotCounts(){
      var poolingDestinations = $('.source_well .aliquot').map(function(_, el){
        return $(el).attr('data-destination-well');
      });

      poolingDestinations = _.uniq(poolingDestinations);

      // Reset data-aliquot-count to 0 for all the destination wells
      $('#destination_plate .well').attr('data-aliquot-count', 0);

      _.each(poolingDestinations, function(wellLocation){
        var aliquotCount = $('.source_aliquot[data-destination-well=' + wellLocation + ']').length;

        $('#destination_plate .well[data-location='+ wellLocation + ']').attr('data-aliquot-count', aliquotCount);
      });

    }

    function newAliquot(destinationWell){
      var location = getLocation(destinationWell);
      var aliquot  = $.createElement('div');

      aliquot.
        attr('id', 'aliquot_' + location).
        addClass('aliquot').
        addClass(coloursByLocation[location]).
        text(location);

      return aliquot;
    }

    function addAliquot(destinationWell){
      if (destinationWell.html().trim() === '') {
        destinationWell.append(newAliquot(destinationWell));
      }
    }

    function getLocation(el){
      return $(el).attr('id').match(/^.*_([A-H]\d+)$/)[1];
    }

    function aliquotsByDestination(el){
      return $('.source_aliquot').not(':contains('+ getLocation(el) +')');
    }

    // function setupHighLightTransfers(){
    //   $('#destination_plate .aliquot').toggle(
    //     function(){
    //     $('#destination_plate .aliquot').not(this).each(SCAPE.dim);
    //     aliquotsByDestination(this).each(SCAPE.dim);
    //   }, undimAliquots);
    // }

    function poolingHandler(){
      setPoolingValue(sourceWell, $(this));
      destinationWell = undefined;
      $('#destination_plate .well').unbind();
      undimAliquots();
    }

    function initialisePoolValues(){
      var i;
      var destination_pools = $('.source_aliquot').map(function(){
        return  [ $(this).text().trim(), $(this).data('pool') ];
      });

      destination_pools = _.uniq(destination_pools);
      for (i=0;i<destination_pools.length; i = i + 2){
        $('#destination_plate .well[data-location=' + destination_pools[i] + ']').attr('data-pool', destination_pools[i+1]);
      }
    }

    // This function ensures that the hidden form values always start with the
    // expected values even if someone reloads the page (otherwise the form will
    // retain the previous values but page won't show them).
    function initialiseTransferFormValues(){
      $('.source_well').each(function(){
        var dest = $(this).find('.aliquot').attr('data-destination-well');
        $(this).find('input').val(dest);
      });
    }

    // Custom pooling code starts here...
    initialisePoolValues();

    initialiseTransferFormValues();

    //Change click to toggle so that operation can be aborted...
    $('.source_well').toggle(
      function(){
        sourceWell    = $(this);
        var sourceAliquot = sourceWell.find('.aliquot');
        var sourcePool    = sourceAliquot.data('pool');

        // Dim other source wells...
        $('.source_aliquot').not(sourceAliquot).each(SCAPE.dim);

        // Remove highlighting behaviour from aliquots on destination plate
        $('#destination_plate .aliquot').unbind();

        // dim wells used by other submissions...
        $('#destination_plate .well').not('[data-pool=""]').not('[data-pool=' + sourcePool + ']').each(SCAPE.dim);

        // Add the handler to unused wells or wells used by this submission...
        $('#destination_plate .well').filter('[data-pool=' + sourcePool +'],[data-pool=""]').click(poolingHandler);
      },

      function() {
        $('#destination_plate .well').unbind();
        undimAliquots();
      }
    );

    resetAliquotCounts();
    // setupHighLightTransfers();
  });
})(window, jQuery);

