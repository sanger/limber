(function($, exports, undefined){
  "use strict";

  ////////////////////////////////////////////////////////////////////
  // Bed Robot Page
  $(function(event) {

    if ($('#robot-verification-bed').length === 0) { return };

    $.ajaxSetup({
      beforeSend: function(xhr) {
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
    });

    var closeIcon = function() {
      return $(document.createElement('button')).
        attr('class','close').attr('aria-label','close').append(
          $(document.createElement('span')).
            attr('aria-hidden','true').text('×')
        );
    }


    SCAPE.robot_beds = {};
    SCAPE.robot_scan = '';

    // var bed_index = 0;

    var newScanned = function(bed,plate,robot){
      var new_li;
      // $('#whole\\['+bed+'\\]').detach();
      new_li = $(document.createElement('li')).
        attr('data-robot',robot).
        attr('data-bed',bed).
        attr('data-labware',plate).
        attr('class','list-group-item list-group-item-action').
        on('click', removeEntry).
        append(
          $(document.createElement('a')).
          attr('href','#').
          attr('class','list-group-item-action')
          .append(
            $(document.createElement('h3')).
            attr('class',"ui-li-heading").
            text('Robot: '+robot)
            )
          .append(
            $(document.createElement('h3')).
            attr('class',"ui-li-heading").
            text('Bed: '+bed)
          ).append(closeIcon()).append(
            $(document.createElement('p')).
            attr('class','ui-li-desc').
            text('Plate: '+plate)
          ).append(
            $(document.createElement('input')).
            attr('type','hidden').attr('id','bed['+bed+']').attr('name','bed['+bed+'][]').
            val(plate)
          )
        );
      SCAPE.robot_beds[bed] = SCAPE.robot_beds[bed] || []
      SCAPE.robot_beds[bed].push(plate);
      $('#start-robot').prop('disabled',true);
      $('#bed_list').append(new_li);
    }

    var removeEntry = function() {
      var lw_index, bed_list;
      bed_list = SCAPE.robot_beds[$(this).attr('data-bed')];
      lw_index = bed_list.indexOf($(this).attr('data-labware'));
      bed_list.splice(lw_index,1);
      if (bed_list.length === 0) { SCAPE.robot_beds[$(this).attr('data-bed')] = undefined };
      $(this).detach();
      $('#bed_list');
    }

    var checkResponse = function(response) {
      if ($('#bed_list').children().length===0) {
        // We don't have any content
        $('#loadingModal').modal('hide');
      } else if (response.valid) {
        pass();
      } else {
        flagBeds(response.beds,response.message);
        fail();
      }

    }

    var flagBeds = function(beds,message) {
      var bad_beds = [];
      $.each(beds, function(bed_id) {
        if (!this) {$('#bed_list li[data-bed="'+bed_id+'"]').addClass('bad_bed list-group-item-danger'); bad_beds.push(bed_id);}
      });
      SCAPE.message('There were problems: '+message,'danger');
    }

    var wait = function() {
      $('#loadingModal').modal({backdrop: 'static', keyboard: false});
    }

    var pass = function() {
      $('#loadingModal').modal('hide');
      SCAPE.message('No problems detected!','success');
      $('#start-robot').prop('disabled',false);
    }

    var fail = function() {
      $('#loadingModal').modal('hide');
      $('#start-robot').prop('disabled',true);
    }

    $('#plate_scan').on('change', function(){
      var plate_barcode, bed_barcode, robot_barcode;
      plate_barcode = this.value
      bed_barcode = $('#bed_scan').val();
      robot_barcode = $('#robot_scan').val();
      SCAPE.robot_scan = robot_barcode
      this.value = "";
      $('#bed_scan').val("");
      $('#bed_scan').focus();
      newScanned(bed_barcode,plate_barcode,robot_barcode);
    });

    $('#validate_layout').on('click',function(){
      wait();
      var ajax = $.ajax({
          dataType: "json",
          url: window.location.pathname+'/verify',
          type: 'POST',
          data: {"beds" : SCAPE.robot_beds, "robot_scan" : SCAPE.robot_scan },
          success: function(data,status) { checkResponse(data); }
        }).fail(function(data,status) { SCAPE.message('The beds could not be validated. There may be network issues, or problems with Sequencescape.','danger'); fail(); });
    })
  });
})(jQuery,window);
