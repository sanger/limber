/*
 * Auto-generated by Sequencescape on 2024-09-04 17:09:09 +0100"
 * Using develop-Y24-190@8b0e5a6
 * bundle exec rake devour:create_config"
 *
 */

/* Our configuration is essentially JSON, so we allow double quotes */
/* eslint quotes: ["error", "double"] */
const resources = [
  {
    "resource": "aliquot",
    "attributes": {
      "tag_oligo": "",
      "tag_index": "",
      "tag2_oligo": "",
      "tag2_index": "",
      "suboptimal": "",
      "library_type": "",
      "insert_size_to": "",
      "study": {
        "jsonApi": "hasOne",
        "type": "study"
      },
      "project": {
        "jsonApi": "hasOne",
        "type": "project"
      },
      "sample": {
        "jsonApi": "hasOne",
        "type": "sample"
      },
      "request": {
        "jsonApi": "hasOne",
        "type": "request"
      },
      "receptacle": {
        "jsonApi": "hasOne",
        "type": "receptacle"
      },
      "tag": {
        "jsonApi": "hasOne",
        "type": "tag"
      },
      "tag2": {
        "jsonApi": "hasOne",
        "type": "tag"
      },
      "library": {
        "jsonApi": "hasOne",
        "type": "receptacle"
      }
    },
    "options": {
    }
  },
  {
    "resource": "asset_audit",
    "attributes": {
      "key": "",
      "message": "",
      "created_by": "",
      "asset_uuid": "",
      "witnessed_by": "",
      "metadata": ""
    },
    "options": {
    }
  },
  {
    "resource": "asset",
    "attributes": {
      "uuid": "",
      "custom_metadatum_collection": {
        "jsonApi": "hasOne",
        "type": "custom_metadatum_collection"
      },
      "comments": {
        "jsonApi": "hasMany",
        "type": "comment"
      }
    },
    "options": {
    }
  },
  {
    "resource": "barcode_printer",
    "attributes": {
      "name": "",
      "uuid": "",
      "print_service": "",
      "barcode_type": ""
    },
    "options": {
    }
  },
  {
    "resource": "between_plate_and_tube",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "between_plate",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "between_plates_by_submission",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "between_specific_tube",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "between_tubes_by_submission",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "comment",
    "attributes": {
      "title": "",
      "description": "",
      "created_at": "",
      "updated_at": "",
      "user": {
        "jsonApi": "hasOne",
        "type": "user"
      },
      "commentable": {
        "jsonApi": "hasOne"
      }
    },
    "options": {
    }
  },
  {
    "resource": "custom_metadatum_collection",
    "attributes": {
      "uuid": "",
      "user_id": "",
      "asset_id": "",
      "metadata": ""
    },
    "options": {
    }
  },
  {
    "resource": "from_plate_to_specific_tube",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "from_plate_to_specific_tubes_by_pool",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "from_plate_to_tube_by_multiplex",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "from_plate_to_tube_by_submission",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "from_plate_to_tube",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "labware",
    "attributes": {
      "uuid": "",
      "name": "",
      "labware_barcode": "",
      "state": "",
      "created_at": "",
      "updated_at": "",
      "purpose": {
        "jsonApi": "hasOne",
        "type": "purpose"
      },
      "custom_metadatum_collection": {
        "jsonApi": "hasOne",
        "type": "custom_metadatum_collection"
      },
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "projects": {
        "jsonApi": "hasMany",
        "type": "project"
      },
      "comments": {
        "jsonApi": "hasMany",
        "type": "comment"
      },
      "receptacles": {
        "jsonApi": "hasMany"
      },
      "ancestors": {
        "jsonApi": "hasMany"
      },
      "descendants": {
        "jsonApi": "hasMany"
      },
      "parents": {
        "jsonApi": "hasMany"
      },
      "children": {
        "jsonApi": "hasMany"
      },
      "child_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "child_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "direct_submissions": {
        "jsonApi": "hasMany",
        "type": "submission"
      },
      "state_changes": {
        "jsonApi": "hasMany",
        "type": "state_change"
      }
    },
    "options": {
    }
  },
  {
    "resource": "lane",
    "attributes": {
      "uuid": "",
      "name": "",
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "projects": {
        "jsonApi": "hasMany",
        "type": "project"
      }
    },
    "options": {
    }
  },
  {
    "resource": "lot_type",
    "attributes": {
      "uuid": "",
      "name": "",
      "template_type": "",
      "target_purpose": {
        "jsonApi": "hasOne",
        "type": "purpose"
      }
    },
    "options": {
    }
  },
  {
    "resource": "lot",
    "attributes": {
      "uuid": "",
      "lot_number": "",
      "lot_type": {
        "jsonApi": "hasOne",
        "type": "lot_type"
      },
      "user": {
        "jsonApi": "hasOne",
        "type": "user"
      },
      "template": {
        "jsonApi": "hasOne"
      },
      "tag_layout_template": {
        "jsonApi": "hasOne",
        "type": "tag_layout_template"
      }
    },
    "options": {
    }
  },
  {
    "resource": "order",
    "attributes": {
      "uuid": "",
      "request_options": ""
    },
    "options": {
    }
  },
  {
    "resource": "pick_list",
    "attributes": {
      "created_at": "",
      "updated_at": "",
      "state": "",
      "links": "",
      "pick_attributes": "",
      "labware_pick_attributes": "",
      "asynchronous": ""
    },
    "options": {
    }
  },
  {
    "resource": "plate_purpose",
    "attributes": {
      "name": "",
      "stock_plate": "",
      "cherrypickable_target": "",
      "input_plate": "",
      "size": "",
      "asset_shape": "",
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "plate_template",
    "attributes": {
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "plate",
    "attributes": {
      "uuid": "",
      "name": "",
      "labware_barcode": "",
      "state": "",
      "created_at": "",
      "updated_at": "",
      "number_of_rows": "",
      "number_of_columns": "",
      "size": "",
      "purpose": {
        "jsonApi": "hasOne",
        "type": "purpose"
      },
      "custom_metadatum_collection": {
        "jsonApi": "hasOne",
        "type": "custom_metadatum_collection"
      },
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "projects": {
        "jsonApi": "hasMany",
        "type": "project"
      },
      "comments": {
        "jsonApi": "hasMany",
        "type": "comment"
      },
      "receptacles": {
        "jsonApi": "hasMany"
      },
      "ancestors": {
        "jsonApi": "hasMany"
      },
      "descendants": {
        "jsonApi": "hasMany"
      },
      "parents": {
        "jsonApi": "hasMany"
      },
      "children": {
        "jsonApi": "hasMany"
      },
      "child_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "child_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "direct_submissions": {
        "jsonApi": "hasMany",
        "type": "submission"
      },
      "state_changes": {
        "jsonApi": "hasMany",
        "type": "state_change"
      },
      "wells": {
        "jsonApi": "hasMany",
        "type": "well"
      }
    },
    "options": {
    }
  },
  {
    "resource": "poly_metadatum",
    "attributes": {
      "key": "",
      "value": "",
      "created_at": "",
      "updated_at": "",
      "metadatable": {
        "jsonApi": "hasOne"
      }
    },
    "options": {
    }
  },
  {
    "resource": "pre_capture_pool",
    "attributes": {
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "primer_panel",
    "attributes": {
      "name": "",
      "programs": ""
    },
    "options": {
    }
  },
  {
    "resource": "project",
    "attributes": {
      "name": "",
      "cost_code": "",
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "purpose",
    "attributes": {
      "uuid": "",
      "name": "",
      "size": "",
      "lifespan": ""
    },
    "options": {
    }
  },
  {
    "resource": "qc_assay",
    "attributes": {
      "lot_number": "",
      "qc_results": {
        "jsonApi": "hasMany",
        "type": "qc_result"
      }
    },
    "options": {
    }
  },
  {
    "resource": "qc_result",
    "attributes": {
      "key": "",
      "value": "",
      "units": "",
      "cv": "",
      "assay_type": "",
      "assay_version": "",
      "created_at": "",
      "asset": {
        "jsonApi": "hasOne",
        "type": "receptacle"
      }
    },
    "options": {
    }
  },
  {
    "resource": "qcable",
    "attributes": {
      "uuid": "",
      "state": "",
      "labware_barcode": "",
      "lot": {
        "jsonApi": "hasOne",
        "type": "lot"
      },
      "asset": {
        "jsonApi": "hasOne"
      }
    },
    "options": {
    }
  },
  {
    "resource": "racked_tube",
    "attributes": {
      "coordinate": "",
      "tube": {
        "jsonApi": "hasOne",
        "type": "tube"
      },
      "tube_rack": {
        "jsonApi": "hasOne",
        "type": "tube_rack"
      }
    },
    "options": {
    }
  },
  {
    "resource": "receptacle",
    "attributes": {
      "uuid": "",
      "name": "",
      "pcr_cycles": "",
      "submit_for_sequencing": "",
      "sub_pool": "",
      "coverage": "",
      "diluent_volume": "",
      "state": "",
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "projects": {
        "jsonApi": "hasMany",
        "type": "project"
      },
      "requests_as_source": {
        "jsonApi": "hasMany",
        "type": "request"
      },
      "requests_as_target": {
        "jsonApi": "hasMany",
        "type": "request"
      },
      "qc_results": {
        "jsonApi": "hasMany",
        "type": "qc_result"
      },
      "aliquots": {
        "jsonApi": "hasMany",
        "type": "aliquot"
      },
      "downstream_assets": {
        "jsonApi": "hasMany"
      },
      "downstream_wells": {
        "jsonApi": "hasMany",
        "type": "well"
      },
      "downstream_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "downstream_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "upstream_assets": {
        "jsonApi": "hasMany"
      },
      "upstream_wells": {
        "jsonApi": "hasMany",
        "type": "well"
      },
      "upstream_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "upstream_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "transfer_requests_as_source": {
        "jsonApi": "hasMany",
        "type": "transfer_request"
      },
      "transfer_requests_as_target": {
        "jsonApi": "hasMany",
        "type": "transfer_request"
      },
      "labware": {
        "jsonApi": "hasOne",
        "type": "labware"
      }
    },
    "options": {
    }
  },
  {
    "resource": "request_type",
    "attributes": {
      "uuid": "",
      "name": "",
      "key": "",
      "for_multiplexing": ""
    },
    "options": {
    }
  },
  {
    "resource": "request",
    "attributes": {
      "uuid": "",
      "role": "",
      "state": "",
      "priority": "",
      "options": "",
      "library_type": "",
      "submission": {
        "jsonApi": "hasOne",
        "type": "submission"
      },
      "order": {
        "jsonApi": "hasOne",
        "type": "order"
      },
      "request_type": {
        "jsonApi": "hasOne",
        "type": "request_type"
      },
      "primer_panel": {
        "jsonApi": "hasOne",
        "type": "primer_panel"
      },
      "pre_capture_pool": {
        "jsonApi": "hasOne",
        "type": "pre_capture_pool"
      },
      "poly_metadata": {
        "jsonApi": "hasMany",
        "type": "poly_metadatum"
      }
    },
    "options": {
    }
  },
  {
    "resource": "sample_manifest",
    "attributes": {
      "supplier_name": ""
    },
    "options": {
    }
  },
  {
    "resource": "sample_metadata",
    "attributes": {
      "cohort": "",
      "collected_by": "",
      "concentration": "",
      "donor_id": "",
      "gender": "",
      "sample_common_name": "",
      "sample_description": "",
      "supplier_name": "",
      "volume": ""
    },
    "options": {
    }
  },
  {
    "resource": "sample",
    "attributes": {
      "name": "",
      "sanger_sample_id": "",
      "uuid": "",
      "control": "",
      "control_type": "",
      "sample_metadata": {
        "jsonApi": "hasOne",
        "type": "sample_metadata"
      },
      "sample_manifest": {
        "jsonApi": "hasOne",
        "type": "sample_manifest"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "component_samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      }
    },
    "options": {
    }
  },
  {
    "resource": "state_change",
    "attributes": {
      "contents": "",
      "customer_accepts_responsibility": "",
      "previous_state": "",
      "reason": "",
      "target_state": "",
      "target_uuid": "",
      "user_uuid": "",
      "uuid": "",
      "user": {
        "jsonApi": "hasOne",
        "type": "user"
      },
      "target": {
        "jsonApi": "hasOne",
        "type": "labware"
      }
    },
    "options": {
    }
  },
  {
    "resource": "study",
    "attributes": {
      "name": "",
      "uuid": "",
      "poly_metadata": {
        "jsonApi": "hasMany",
        "type": "poly_metadatum"
      }
    },
    "options": {
    }
  },
  {
    "resource": "submission_template",
    "attributes": {
      "name": "",
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "submission",
    "attributes": {
      "uuid": "",
      "name": "",
      "state": "",
      "created_at": "",
      "updated_at": "",
      "used_tags": "",
      "lanes_of_sequencing": ""
    },
    "options": {
    }
  },
  {
    "resource": "tag_group_adapter_type",
    "attributes": {
      "name": "",
      "tag_groups": {
        "jsonApi": "hasMany",
        "type": "tag_group"
      }
    },
    "options": {
    }
  },
  {
    "resource": "tag_group",
    "attributes": {
      "uuid": "",
      "name": "",
      "tags": "",
      "tag_group_adapter_type": {
        "jsonApi": "hasOne",
        "type": "tag_group_adapter_type"
      }
    },
    "options": {
    }
  },
  {
    "resource": "tag_layout_template",
    "attributes": {
      "uuid": "",
      "name": "",
      "direction": "",
      "walking_by": "",
      "tag_group": {
        "jsonApi": "hasOne",
        "type": "tag_group"
      },
      "tag2_group": {
        "jsonApi": "hasOne",
        "type": "tag_group"
      }
    },
    "options": {
    }
  },
  {
    "resource": "tag",
    "attributes": {
      "oligo": "",
      "map_id": "",
      "tag_group": {
        "jsonApi": "hasOne",
        "type": "tag_group"
      }
    },
    "options": {
    }
  },
  {
    "resource": "transfer_request",
    "attributes": {
      "uuid": "",
      "state": "",
      "volume": "",
      "target_asset": {
        "jsonApi": "hasOne",
        "type": "receptacle"
      },
      "source_asset": {
        "jsonApi": "hasOne",
        "type": "receptacle"
      },
      "submission": {
        "jsonApi": "hasOne",
        "type": "submission"
      }
    },
    "options": {
    }
  },
  {
    "resource": "transfer_template",
    "attributes": {
      "name": "",
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "transfer",
    "attributes": {
      "uuid": "",
      "source_uuid": "",
      "destination_uuid": "",
      "user_uuid": "",
      "transfers": "",
      "transfer_template_uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "tube_purpose",
    "attributes": {
      "name": "",
      "purpose_type": "",
      "target_type": "",
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "tube_rack_status",
    "attributes": {
      "uuid": ""
    },
    "options": {
    }
  },
  {
    "resource": "tube_rack",
    "attributes": {
      "uuid": "",
      "created_at": "",
      "updated_at": "",
      "labware_barcode": "",
      "size": "",
      "number_of_rows": "",
      "number_of_columns": "",
      "name": "",
      "tube_locations": "",
      "racked_tubes": {
        "jsonApi": "hasMany",
        "type": "racked_tube"
      },
      "comments": {
        "jsonApi": "hasMany",
        "type": "comment"
      },
      "purpose": {
        "jsonApi": "hasOne",
        "type": "purpose"
      }
    },
    "options": {
    }
  },
  {
    "resource": "tube",
    "attributes": {
      "uuid": "",
      "name": "",
      "labware_barcode": "",
      "state": "",
      "created_at": "",
      "updated_at": "",
      "purpose": {
        "jsonApi": "hasOne",
        "type": "purpose"
      },
      "custom_metadatum_collection": {
        "jsonApi": "hasOne",
        "type": "custom_metadatum_collection"
      },
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "projects": {
        "jsonApi": "hasMany",
        "type": "project"
      },
      "comments": {
        "jsonApi": "hasMany",
        "type": "comment"
      },
      "receptacles": {
        "jsonApi": "hasMany"
      },
      "ancestors": {
        "jsonApi": "hasMany"
      },
      "descendants": {
        "jsonApi": "hasMany"
      },
      "parents": {
        "jsonApi": "hasMany"
      },
      "children": {
        "jsonApi": "hasMany"
      },
      "child_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "child_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "direct_submissions": {
        "jsonApi": "hasMany",
        "type": "submission"
      },
      "state_changes": {
        "jsonApi": "hasMany",
        "type": "state_change"
      },
      "aliquots": {
        "jsonApi": "hasMany",
        "type": "aliquot"
      },
      "transfer_requests_as_target": {
        "jsonApi": "hasMany",
        "type": "transfer_request"
      },
      "receptacle": {
        "jsonApi": "hasOne",
        "type": "receptacle"
      }
    },
    "options": {
    }
  },
  {
    "resource": "user",
    "attributes": {
      "uuid": "",
      "login": "",
      "first_name": "",
      "last_name": ""
    },
    "options": {
    }
  },
  {
    "resource": "volume_update",
    "attributes": {
      "created_by": "",
      "target_uuid": "",
      "volume_change": ""
    },
    "options": {
    }
  },
  {
    "resource": "well",
    "attributes": {
      "uuid": "",
      "name": "",
      "pcr_cycles": "",
      "submit_for_sequencing": "",
      "sub_pool": "",
      "coverage": "",
      "diluent_volume": "",
      "state": "",
      "position": "",
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      },
      "studies": {
        "jsonApi": "hasMany",
        "type": "study"
      },
      "projects": {
        "jsonApi": "hasMany",
        "type": "project"
      },
      "requests_as_source": {
        "jsonApi": "hasMany",
        "type": "request"
      },
      "requests_as_target": {
        "jsonApi": "hasMany",
        "type": "request"
      },
      "qc_results": {
        "jsonApi": "hasMany",
        "type": "qc_result"
      },
      "aliquots": {
        "jsonApi": "hasMany",
        "type": "aliquot"
      },
      "downstream_assets": {
        "jsonApi": "hasMany"
      },
      "downstream_wells": {
        "jsonApi": "hasMany",
        "type": "well"
      },
      "downstream_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "downstream_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "upstream_assets": {
        "jsonApi": "hasMany"
      },
      "upstream_wells": {
        "jsonApi": "hasMany",
        "type": "well"
      },
      "upstream_plates": {
        "jsonApi": "hasMany",
        "type": "plate"
      },
      "upstream_tubes": {
        "jsonApi": "hasMany",
        "type": "tube"
      },
      "transfer_requests_as_source": {
        "jsonApi": "hasMany",
        "type": "transfer_request"
      },
      "transfer_requests_as_target": {
        "jsonApi": "hasMany",
        "type": "transfer_request"
      },
      "labware": {
        "jsonApi": "hasOne",
        "type": "labware"
      }
    },
    "options": {
    }
  },
  {
    "resource": "work_order",
    "attributes": {
      "order_type": "",
      "quantity": "",
      "state": "",
      "options": "",
      "at_risk": "",
      "study": {
        "jsonApi": "hasOne",
        "type": "study"
      },
      "project": {
        "jsonApi": "hasOne",
        "type": "project"
      },
      "source_receptacle": {
        "jsonApi": "hasOne"
      },
      "samples": {
        "jsonApi": "hasMany",
        "type": "sample"
      }
    },
    "options": {
    }
  }
]

export default resources
