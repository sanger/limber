const tubeFactory = function (tubeOptions = {}) {
  const tubeDefaults = {
    name: 'Tube NT1S',
    uuid: 'tube-uuid',
    id: '1',
    labware_barcode: {
      ean13_barcode: '1220542971784',
      human_barcode: 'NT1S',
      machine_barcode: '1220542971784',
    },
    state: 'passed',
    requests_as_source: [],
    receptacle: { uuid: 'receptacle-uuid', aliquots: [{ request: null }] },
    purpose: { uuid: 'purpose-uuid', name: 'purpose-name' },
  }
  return { ...tubeDefaults, ...(tubeOptions || {}) }
}

export default tubeFactory
