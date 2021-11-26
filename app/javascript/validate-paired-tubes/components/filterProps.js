const filterProps = {
  fields: {
    tubes: 'labware_barcode,uuid,purpose,receptacle',
    purposes: 'name,uuid',
    receptacles: 'qc_results'
  },
  includes: 'purpose,receptacle.qc_results'
}

export default filterProps
