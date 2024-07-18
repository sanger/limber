const filterProps = {
  plateFields: {
    plates: 'labware_barcode,wells,uuid,number_of_rows,number_of_columns',
    requests: 'uuid,state',
    wells: 'position,requests_as_source,aliquots,uuid',
    aliquots: 'request',
  },
  plateIncludes: 'wells,wells.requests_as_source,wells.aliquots.request',
  tubeIncludes: 'receptacle',
  requestsFilter: 'lb-null-filter',
}

export default filterProps
