const tubeFactory = function(tubeOptions = {}) {
  let uuid = tubeOptions.uuid || 'tube-uuid'
  let id = tubeOptions.id || '1'

  const tubeDefaults = {
    name: 'Tube NT1S',
    uuid: uuid,
    id: id,
    labware_barcode: { ean13_barcode: '1220542971784', human_barcode: 'NT1S', machine_barcode: '1220542971784' },
    state: 'passed',
    requests_as_source: [],
    receptacle: { uuid: 'receptacle-uuid', aliquots: [{ request: null }] }
  }
  return { ...tubeDefaults, ...(tubeOptions || {}) }
}

export default tubeFactory
