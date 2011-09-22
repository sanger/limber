$('#search-page').live('pagecreate', function(event){
  // Users should start the page by scanning in...
  $('#card_id').focus();


  $('#card_id').change(function(){
    if ($(this).val()) {
      $('.ui-header').removeClass('ui-bar-a').addClass('ui-bar-b');
    } else {
      $('.ui-header').removeClass('ui-bar-b').addClass('ui-bar-a');
    }
  });

  // Trap the carriage return sent by the swipecard reader
  $("#card_id").bind("keydown", function(e) {
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
  window.SCAPE = {};

  SCAPE.footerLinkHandler = function(){
    var viewBlock = $(this).attr('data-view-class');
    var targetBlock = $(this).attr('rel');

    $('.'+viewBlock).filter(':visible').fadeOut('fast',function(){
      $('#'+targetBlock).fadeIn('fast');
    });

  };

  $(function(){
    $('.navbar-link').click(SCAPE.footerLinkHandler);
  });
});


$('#admin-page').live('pagecreate',function(event) {

  $('#plate_edit').submit(function() {
    if ($('#card_id').val().length === 0) {
      alert("Please scan your swipecard...");
      return false;
    }
  });

  // Trap the carriage return sent by the swipecard reader
  $("#card_id").bind("keydown", function(e) {
    var code=e.charCode || e.keyCode;
    if (code==13) {
      return false;
    }
  });
});

$('#creation-page').live('pagecreate',function(event) {
  var transfers = {
    'Transfer columns 1-1':  '.col-1',
    'Transfer columns 1-2':  '.col-1,.col-2',
    'Transfer columns 1-3':  '.col-1,.col-2,.col-3',
    'Transfer columns 1-4':  '.col-1,.col-2,.col-3,.col-4',
    'Transfer columns 1-6':  '.col-1,.col-2,.col-3,.col-4,.col-5,.col-6',
    'Transfer columns 1-12': '.col-all'
  };

  function template_display(){
    $('.aliquot').hide();
    $(transfers[$('#plate_transfer_template_uuid option:selected').text()]).find('.aliquot').show();
  }

  template_display();
  $('#plate_transfer_template_uuid').change(template_display);
});
