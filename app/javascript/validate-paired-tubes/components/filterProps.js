const filterProps = {
  fields: {
    tubes: 'labware_barcode,uuid,purpose,receptacle,state',
    purposes: 'uuid',
    receptacles: 'qc_results,downstream_tubes'
  },
  includes: 'purpose,receptacle.qc_results,receptacle.downstream_tubes'
}

export default filterProps
