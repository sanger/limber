(function($, exports, undefined){
  "use strict";

  //= require lib/status_collector

  // TAG CREATION
  $(document).ready(function(){
    if ($('#tag-creation-page').length === 0) { return };
    var qcLookup;

    $.ajaxSetup({
      beforeSend: function(xhr) {
        xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
      }
    });

    qcLookup = function(barcodeBox,collector) {
      if (barcodeBox.length == 0) { return false; }
      var qc_lookup = this, status;
      this.inputBox = barcodeBox;
      this.infoPanelId = $('#'+barcodeBox.data('info-panel'));
      this.qcableType  = barcodeBox.data('qcable-type');
      this.approvedTypes = SCAPE[barcodeBox.data('approved-list')];
      this.required = this.inputBox.parents('.required').length > 0;
      this.inputBox.on('change',function(){
        qc_lookup.resetStatus();
        qc_lookup.requestPlate(this.value);
      });
      this.monitor = collector.register(!this.required);
    };

    qcLookup.prototype = {
      resetStatus: function() {
        this.monitor.fail();
        this.infoPanelId.find('dd').text('');
        this.infoPanelId.find('input').val(null);
      },
      requestPlate: function(barcode) {
        if ( this.inputBox.val()==="" && !this.required ) { return this.monitor.pass();}
        $.ajax({
          type: 'POST',
          dataType: "json",
          url: '/search/qcables',
          data: 'qcable_barcode='+this.inputBox.val()
      }).then(this.success(),this.error());
      },
      success: function() {
        var qc_lookup = this;
        return function(response) {
          if (response.error) {
            qc_lookup.message(response.error,'danger')
          } else if (response.qcable) {
            qc_lookup.plateFound(response.qcable)
          } else {
            console.log(response);
            qc_lookup.message('An unexpected response was received. Please contact support.','danger');
          }
        };
      },
      error: function() {
        var qc_lookup = this;
        return function() {
          qc_lookup.message('The barcode could not be found. There may be network issues, or problems with Sequencescape.','danger')
        };
      },
      plateFound: function(qcable) {
        this.populateData(qcable);
        if (this.validPlate(qcable)) {
          this.message('The ' + qcable.qcable_type + ' is suitable.'+this.errors,'success');
          SCAPE.update_layout();
          this.monitor.pass();
        } else {
          this.message(' The ' + qcable.qcable_type + ' is not suitable.'+this.errors,'danger')
        }
      },
      populateData: function(qcable) {
        this.infoPanelId.find('dd.lot-number').text(qcable.lot_number);
        this.infoPanelId.find('dd.template').text(qcable.tag_layout);
        this.infoPanelId.find('dd.state').text(qcable.state);
        this.infoPanelId.find('.asset_uuid').val(qcable.asset_uuid);
        this.infoPanelId.find('.template_uuid').val(qcable.template_uuid);
      },
      validPlate: function(qcable) {
        this.errors = '';

        if (qcable.state !== 'available') { this.errors += ' The scanned item is not available.' };
        if (qcable.type  !== this.qcableType ) { this.errors += ' The scanned item is not a(n) ' + this.qcableType + '.' };
        this.validateTemplate(qcable);
        return this.errors === '';
      },
      validateTemplate: function(qcable) {
        if (this.approvedTypes[qcable.template_uuid] === undefined) { this.errors += ' It does not contain suitable tags.'}
      },
      message: function(message,status) {
      this.infoPanelId.find('.qc_validation_report').empty().append(
        $(document.createElement('div')).
          addClass('alert').
          addClass('alert-'+status).
          text(message)
        );
      },
      errors: ''
    };

    var qcCollector = new statusCollector(
      function () {$('#plate_submit').prop('disabled',false) },
      function () {$('#plate_submit').prop('disabled',true)  }
    );

    new qcLookup($('#plate_tag_plate_barcode'),qcCollector);
    new qcLookup($('#plate_tag2_tube_barcode'),qcCollector);

    /* Disables form submit (eg. by enter) if the button is disabled. Seems safari doesn't do this by default */
    $('form#plate_new').on('submit',function(){ return !$('input#plate_submit')[0].disabled } )

    $.extend(SCAPE, {

      tagpaletteTemplate     : _.template(SCAPE.tag_palette_template),
      substitutionTemplate  : _.template(SCAPE.substitution_tag_template),

      update_layout: function () {

        var tags = $(SCAPE.tag_layouts[$('#plate_tag_plate_template_uuid').val()]);

        tags.each(function(index) {
          $('#tagging-plate #aliquot_'+this[0]).
            hide('fast').text(this[1][1]).
            addClass('aliquot colour-'+this[1][0]).
            addClass('tag-'+this[1][1]).
            show('fast');
        });

      }
    });


    $('#tagging-plate .aliquot').removeClass('green orange red');

    SCAPE.update_layout();
    $('#plate_tag_plate_template_uuid').change(SCAPE.update_layout);

  });

})(jQuery,window);
