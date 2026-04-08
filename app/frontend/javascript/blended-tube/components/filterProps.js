const filterProps = {
  tubeIncludes: 'receptacle.aliquots.sample,purpose,ancestors,ancestors.purpose',
  tubeFields: {
    tubes: 'labware_barcode,uuid,receptacle,state,purpose,ancestors',
    purposes: 'name',
    plates: 'labware_barcode,purpose',
    aliquots: 'sample',
    samples: 'name',
  },
  requestsFilter: 'lb-null-filter',
}

export default filterProps
