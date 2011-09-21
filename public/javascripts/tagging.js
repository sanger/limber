$(function(){
(function($, _, undefined){

 window.SCAPE = {
 
  tagPalletTemplate     : _.template($('#tag-pallet-template').html()),
  substitutionTemplate  : _.template($('#substitution-tag-template').html()),
  dim              : function() { $(this).fadeTo('fast', 0.2); },

  updateTagPallet  : function() {
    var tagPallet = $('#tag-pallet');

    tagPallet.empty();

    var currentTagGroup   = $(window.tags_by_name[$('#plate_tag_layout_template_uuid option:selected').text()]);
    var currentlyUsedTags = $('.aliquot').map(function(){ return parseInt($(this).text(), 10); });
    var unusedTags        = _.difference(currentTagGroup, currentlyUsedTags);
    var listItems         = unusedTags.reduce(
      function(memo, tagId) { return memo + SCAPE.tagPalletTemplate({tag_id: tagId}); }, '<li data-role="list-divider" class="ui-li ui-li-divider ui-btn ui-bar-b ui-corner-top ui-btn-up-undefined">Replacement Tags</li>');

    tagPallet.append(listItems);
    $('#tag-pallet li:last').addClass('ui-li ui-li-static ui-body-c ui-corner-bottom');

  },

  tagSubstitutionHandler : function() {
    var sourceAliquot = $(this);
    var originalTag   = sourceAliquot.text();

    // Dim other tags...
    $('.aliquot').not('.tag-'+originalTag).each(SCAPE.dim);

    SCAPE.updateTagPallet();

    // Show the tag pallet...
    $('#instructions').fadeOut(function(){
      $('#replacement-tags').fadeIn();
    });


    function palletTagHandler() {
      var newTag = $(this).text();

      // Find all the aliquots using the original tag
      // swap their tag classes and text
      $('.aliquot.tag-'+originalTag).
        hide().
        removeClass('tag-'+originalTag).
        addClass('tag-'+newTag).
        text(newTag).
        addClass('selected-aliquot').
        fadeIn('slow');

      // Add the substitution as a hidden field and li
      $('#substitutions ul').append(SCAPE.substitutionTemplate({original_tag_id: originalTag, replacement_tag_id: newTag}));
			$('#substitutions ul').listview('refresh');

      SCAPE.resetHandler();
    }
    // Remove old behaviour and add the new to available-tags
    $('.available-tag').unbind().click(palletTagHandler);

  },


  update_layout : function () {
    var tags = $(window.tag_layouts[$('#plate_tag_layout_template_uuid option:selected').text()]);
    var substituteTags = tags;

    tags.each(function(index) {
        $('#aliquot_'+this[0]).
          hide().text(this[1][1]).
          removeClass().
          addClass('aliquot colour-'+this[1][0]).
          addClass('tag-'+this[1][1]).
          fadeIn();
    });

    SCAPE.resetHandler();
    SCAPE.resetSubstitutions();
  },

  resetSubstitutions : function() {
    $('#substitutions ul').empty();
    $('.aliquot').removeClass('selected-aliquot');
  },

  resetHandler : function() {
    $('.aliquot').css('opacity', 1);
    $('.available-tags').unbind();
    $('#replacement-tags').fadeOut(function(){
      $('#instructions').fadeIn();
    });
  }

 };


})(jQuery, _);

    $('.aliquot').removeClass('green orange red');

    SCAPE.update_layout();
    $('#plate_tag_layout_template_uuid').change(SCAPE.update_layout);
    $('.aliquot').toggle(SCAPE.tagSubstitutionHandler, SCAPE.resetHandler);

  });
