const filterProps = {
  'primer-panel': {
    plateFields: { plates: 'labware_barcode,wells,uuid,number_of_rows,number_of_columns',
      requests: 'primer_panel,uuid,state,library_type',
      wells: 'position,requests_as_source,aliquots,uuid',
      aliquots: 'request' },
    plateIncludes: 'wells,wells.requests_as_source,wells.requests_as_source.primer_panel,wells.aliquots.request.primer_panel',
    requestsFilter: 'lb-primer-panel-filter',
  },
  'submission-and-library-type': {
    plateFields: { plates: 'labware_barcode,wells,uuid,number_of_rows,number_of_columns',
      requests: 'uuid,state,library_type,submission',
      wells: 'position,requests_as_source,aliquots,uuid',
      aliquots: 'request' },
    plateIncludes: 'wells,wells.requests_as_source,wells.requests_as_source.submission,wells.aliquots.request,wells.aliquots.request.submission',
    requestsFilter: 'lb-null-filter',
  },
  'null': {
    plateFields: { plates: 'labware_barcode,wells,uuid,number_of_rows,number_of_columns',
      requests: 'uuid,state',
      wells: 'position,requests_as_source,aliquots,uuid',
      aliquots: 'request' },
    plateIncludes: 'wells,wells.requests_as_source,wells.aliquots.request',
    requestsFilter: 'lb-null-filter',
  }
}

export default filterProps
