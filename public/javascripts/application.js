(function($, exports, undefined){
  "use strict";

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

(function($, exports, undefined){
  "use strict";

  // Set up the SCAPE namespace
  if (exports.SCAPE === undefined) {
    exports.SCAPE = {};
  }


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

  controlTemplate:  '<fieldset id="plate-view-control" data-role="controlgroup" data-type="horizontal">' +
                    '<input type="radio" name="radio-choice-1" id="radio-choice-1" value="summary-view" checked="checked" />' +
                    '<label for="radio-choice-1">Summary</label>' +
                    '<input type="radio" name="radio-choice-1" id="radio-choice-2" value="pools-view"  />' +
                    '<label for="radio-choice-2">Pools</label>' +
                    '<input type="radio" name="radio-choice-1" id="radio-choice-3" value="samples-view"  />' +
                    '<label for="radio-choice-3">Samples</label> </fieldset>',

  displayReason: function() {
    if($('.reason:visible').length === 0) {
      $('#'+$('#state option:selected').val()).slideDown('slow').find('select:disabled').selectmenu('enable');
    } 
    else {
      $('.reason').not('#'+$('#state option:selected').val()).slideUp('slow', function(){
        $('#'+$('#state option:selected').val()).slideDown('slow').find('select:disabled').selectmenu('enable');
      });
    }

  },


  dim: function() { 
    $(this).fadeTo('fast', 0.2);
    return this;
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

    that.poolsArray = function(){
      var poolsArray = _.toArray(that.plate.pools);

      poolsArray = _.sortBy(poolsArray, function(pool){
        return pool.wells[0];
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

        that.control.find('input:radio[name=radio-choice-1]:eq(1)').
          attr('checked',true);


        that.control.find('input:radio').checkboxradio("refresh");
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


  illuminaBPlateView: function(plate) {
    var plateElement = $(this);
    plateElement.before(SCAPE.controlTemplate);
    var control = $('#plate-view-control');

    var viewModel = new SCAPE.PlateViewModel(plate, plateElement, control);



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
    illuminaBPlateView: SCAPE.illuminaBPlateView,
    dim:                SCAPE.dim
  });


  // ########################################################################
  // # Page events....
  $(document).on('pageinit', function(){
    // Trap the carriage return sent by the swipecard reader
    $(document).on("keydown", "input.card-id", function(e) {
      var code=e.charCode || e.keyCode;
      if (code==13) {
        $('input[data-type="search"], .plate-barcode').last().focus();
        return false;
      }

    });

    var myPlateButtonObserver = function(event){
      if ($(event.currentTarget).val()) {
          $('.show-my-plates-button').button('disable');
      } else if ($('input.card-id').val()) {
          $('.show-my-plates-button').button('enable');
      }
    };

    $(document).on("keyup", ".plate-barcode", myPlateButtonObserver);
    $(document).on("keyup", ".card-id", myPlateButtonObserver);

    // Trap the carriage return sent by barcode scanner
    $(document).on("keydown", ".plate-barcode", function(event) {
      var code=event.charCode || event.keyCode;
      // Check for carrage return (key code 13)
      if (code==13) {
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

  $(document).on('pagecreate', '#plate-show-page', function(event) {
    // Set up the plate element as an illuminaBPlate...
    $('#plate').illuminaBPlateView(SCAPE.labware);
    $('#well-failures').on('click','.plate-view .aliquot:not(".permanent-failure")', SCAPE.failWellToggleHandler);
  });


  $(document).on('pagecreate', '.show-page', function(event) {

    var tabsForState = '#'+SCAPE.labware.tabStates[SCAPE.labware.state].join(', #');

    $('#navbar li').not(tabsForState).addClass('ui-disabled');
    $('#'+SCAPE.labware.tabStates[SCAPE.labware.state][0]).find('a').addClass('ui-btn-active');


    SCAPE.linkHandler = function(){
      var targetTab = $(this).attr('rel');
      var targetIds = '#'+SCAPE.labware.tabViews[targetTab].join(', #');

      $('.scape-ui-block').
        not(targetIds).
        filter(':visible').
        fadeOut().
        promise().
        done( function(){ $(targetIds).fadeIn(); } );
    };

    var targetTab = SCAPE.labware.tabStates[SCAPE.labware.state][0];
    var targetIds = '#'+SCAPE.labware.tabViews[targetTab].join(', #');
    $(targetIds).not(':visible').fadeIn();



    $('.show-page').on('click', '.navbar-link', SCAPE.linkHandler);

    // State changes reasons...
    // SCAPE.displayReason();
    $('.show-page').on('change','#state', SCAPE.displayReason);
  });

  $(document).on('pageinit', '#admin-page', function(event) {

    $('#plate_edit').submit(function() {
      if ($('#card_id').val().length === 0) {
        alert("Please scan your swipecard...");
        return false;
      }
    });

    // State changes reasons...
    SCAPE.displayReason();
    $('#admin-page').on('change','#state', SCAPE.displayReason);
  });


  $(document).on('pagecreate', '#tag-creation-page', function(){

    $.extend(SCAPE, {

      tagpaletteTemplate     : _.template(SCAPE.tag_palette_template),
      substitutionTemplate  : _.template(SCAPE.substitution_tag_template),

      updateTagpalette  : function() {
        var tagpalette = $('#tag-palette');

        tagpalette.empty();

        var currentTagGroup   = $(SCAPE.tags_by_name[$('#plate_tag_layout_template_uuid option:selected').text()]);
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
        $('.aliquot').not('.tag-'+originalTag).addClass('dimmed');
        sourceAliquot.addClass('selected-aliquot');

        SCAPE.updateTagpalette();

        // Show the tag palette...
        $('#instructions').
          fadeOut().
          promise().
          done(function(){
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
        var tags = $(SCAPE.tag_layouts[$('#plate_tag_layout_template_uuid option:selected').text()]);

        tags.each(function(index) {
          $('#tagging-plate #aliquot_'+this[0]).
            hide('fast').text(this[1][1]).
            addClass('aliquot colour-'+this[1][0]).
            addClass('tag-'+this[1][1]).
            show('fast');
        });

        SCAPE.resetHandler();
        SCAPE.resetSubstitutions();
      },

      resetSubstitutions : function() {
        $('#substitutions ul').empty();
        $('#tagging-plate .aliquot').removeClass('selected-aliquot');
      },

      resetHandler : function() {
        $('.aliquot').removeClass('selected-aliquot dimmed');
        $('.available-tags').unbind();
        $('#replacement-tags').
          fadeOut().
          promise().
          done(function(){
          $('#instructions').fadeIn();
        });
      }

    });


    $('#tagging-plate .aliquot').removeClass('green orange red');

    SCAPE.update_layout();
    $('#plate_tag_layout_template_uuid').change(SCAPE.update_layout);
    $('#tagging-plate .aliquot').toggle(SCAPE.tagSubstitutionHandler, SCAPE.resetHandler);

  });

})(jQuery, window);

