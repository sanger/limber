(function($, exports, undefined){
  "use strict";

  //= require lib/tag_collector
  //= require lib/validator

  // TAG CREATION
  $(document).ready(function(){
    if ($('#tag-creation-page').length === 0) { return; }
    var qcLookup;

    //= require lib/ajax_support

    // Set up some null objects
    var unknownTemplate = { unknown: true, dual_index: false };
    var unkownQcable = { template_uuid: 'not-loaded' };

    qcLookup = function(barcodeBox, collector) {
      if (barcodeBox.length === 0) { return false; }

      var qc_lookup = this, status;
      this.inputBox = barcodeBox;

      // the `data` attribute is set when declaring the element in tagged_plate,html.erb
      this.infoPanel = $('#'+barcodeBox.data('info-panel'));
      this.dualIndex = barcodeBox.data('dual-index');
      this.approvedTypes = SCAPE[barcodeBox.data('approved-list')];
      this.required = this.inputBox[0].required;

      // add an onchange event to the box, to look up the plate
      this.inputBox.on('change', function(){
        qc_lookup.resetStatus();
        qc_lookup.requestPlate(this.value);
      });
      this.monitor = collector.register(!this.required, this);

      // set initial values for the tag plate data
      this.qcable = unkownQcable;
      this.template = unknownTemplate;
    };

    // why is this called `qcLookup`? Shouldn't it be tagPlateLookup or similar?
    qcLookup.prototype = {
      resetStatus: function() {
        this.monitor.fail();
        this.infoPanel.find('dd').text('');
        this.infoPanel.find('input').val(null);
      },
      requestPlate: function(barcode) {
        if ( this.inputBox.val()==="" && !this.required ) { return this.monitor.pass();}
        // find the qcable (tag plate) based on the barcode scanned in by the user
        $.ajax({
          type: 'POST',
          dataType: "json",
          url: '/search/qcables',
          data: 'qcable_barcode='+this.inputBox.val()
      }).then(this.success(), this.error());
      },
      success: function() {
        var qc_lookup = this;
        return function(response) {
          if (response.error) {
            qc_lookup.message(response.error,'danger');
          } else if (response.qcable) {
            // if response is as expected, load some data
            qc_lookup.plateFound(response.qcable);
          } else {
            qc_lookup.message('An unexpected response was received. Please contact support.','danger');
          }
        };
      },
      error: function() {
        var qc_lookup = this;
        return function() {
          qc_lookup.message('The barcode could not be found. There may be network issues, or problems with Sequencescape.','danger');
        };
      },
      validators: [
        // `t` is a qcLookup object
        // The data for t.template comes from app/models/labware_creators/tagging/tag_collection.rb
        // t.template.dual_index is true if the scanned tag plate contains both i5 and i7 tags together in its wells (is a UDI plate)
        // t.dualIndex is true if there are multiple source plates from the submission, which will be pooled...
        // ... and therefore an i5 tag (tag 2) is needed (from either a tube or UDI plate)
        new validator(function(t) { return t.qcable.state == 'available'; }, 'The scanned item is not available.'),
        new validator(function(t) { return !t.template.unknown; }, 'It is an unrecognised template.'),
        new validator(function(t) { return t.template.approved; }, 'It is not approved for use with this pipeline.'),
        new validator(function(t) { return !(t.dualIndex && t.template.used && t.template.dual_index); }, 'This template has already been used.'),
        new validator(function(t) { return !(t.dualIndex && !t.template.dual_index); }, 'Pool has been tagged with a UDI plate. UDI plates must be used.'),
        new validator(function(t) { return !(t.dualIndex == false && t.template.dual_index); }, 'Pool has been tagged with tube. Dual indexed plates are unsupported.'),
        new validator(
          function(t) { return (SCAPE.enforceSameTemplateWithinPool ? t.template.matches_templates_in_pool : true) },
          'It doesn\'t match those already used for other plates in this submission pool.'
        )
      ],
      //
      // The major function that runs when a tag plate is scanned into the box
      // Loads tag plate data into `qcable` and `template`
      // Adds visible information to the information panel
      // Validates whether the tag plate is suitable
      // Updates the plate diagram with tag numbers
      //
      plateFound: function(qcable) {
        this.qcable = qcable;
        this.template = this.approvedTypes[qcable.template_uuid] || unknownTemplate;
        this.populateData();

        if (this.validPlate()) {
          this.message('The ' + qcable.qcable_type + ' is suitable.', 'success');
          SCAPE.update_layout();
          this.monitor.pass();
        } else {
          this.message(' The ' + qcable.qcable_type + ' is not suitable.' + this.errors,'danger');
          this.monitor.fail();
        }
      },
      populateData: function() {
        // add information retrieved about the scanned tag plate to the information panel for the user to see
        this.infoPanel.find('dd.lot-number').text(this.qcable.lot_number);
        this.infoPanel.find('dd.template').text(this.qcable.tag_layout);
        this.infoPanel.find('dd.state').text(this.qcable.state);
        this.infoPanel.find('.asset_uuid').val(this.qcable.asset_uuid);
        this.infoPanel.find('.template_uuid').val(this.qcable.template_uuid);
      },
      validPlate: function() {
        // run through the `validators`, and collect any errors
        this.errors = '';
        for (var i =0; i < this.validators.length; i+=1) {
          var response = this.validators[i].validate(this);
          if (!response.valid) { this.errors += ' ' + response.message; }
        }
        return this.errors === '';
      },
      message: function(message, status) {
        this.infoPanel.find('.qc_validation_report').empty().append(
          $(document.createElement('div')).
            addClass('alert').
            addClass('alert-'+status).
            text(message)
        );
      },
      dual: function() {
        return this.template.dual_index;
      },
      errors: ''
    };

    var qcCollector = new tagStatusCollector(
      SCAPE.dualRequired,
      function () {
        $('#submit-summary').text('Marks the tag sources as used, and convert the tag plate.');
        $('#plate_submit').prop('disabled', false);
      },
      function (message) {
        $('#submit-summary').text(message);
        $('#plate_submit').prop('disabled', true);
      }
    );

    new qcLookup($('#plate_tag_plate_barcode'), qcCollector);
    new qcLookup($('#plate_tag2_tube_barcode'), qcCollector);

    /* Disables form submit (eg. by enter) if the button is disabled. Seems safari doesn't do this by default */
    $('form#plate_new').on('submit', function(){ return !$('input#plate_submit')[0].disabled; } );

    $.extend(SCAPE, {
      fetch_tags: function () {
        var selected_layout = $('#plate_tag_plate_template_uuid').val();
        if (SCAPE.tag_plates_list[selected_layout] === undefined) {
          return $([]);
        } else {
          return $(SCAPE.tag_plates_list[selected_layout].tags);
        }
      },
      update_layout: function () {

        var tags = this.fetch_tags();

        tags.each(function(index) {
          $('#tagging-plate #aliquot_'+this[0]).
            hide('fast').text(this[1][1]).
            addClass('aliquot colour-'+this[1][0]).
            addClass('tag-'+this[1][1]).
            show('fast');
        });

      }
    });
    SCAPE.update_layout();
   // $('#plate_tag_plate_template_uuid').change(SCAPE.update_layout);
  });
})(jQuery,window);
