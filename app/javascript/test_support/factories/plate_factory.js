import buildArray from 'shared/buildArray'
import { indexToName } from 'shared/wellHelpers'
import wellFactory from 'test_support/factories/well_factory'

const plateFactory = function(options = {}) {
  const { filledWells, wellOptions, ...plateOptions } = options
  let uuid = plateOptions.uuid || 'plate-uuid'
  // Bit inefficient, in that we generate wells even if we immediately override them
  const plateDefaults = {
    name: 'Plate DN1S',
    uuid: uuid,
    labwareBarcode: { ean13_barcode: '1220542971784', human_barcode: 'DN1S', machine_barcode: '1220542971784' },
    numberOfColumns: 12,
    numberOfRows: 8,
    state: 'passed',
    wells: buildArray(filledWells||96, (interation) => wellFactory({
      ...{
        uuid: `${uuid}-well-${interation}`,
        position: { name: indexToName(interation, 12, 8) } },
      ...wellOptions
    }) )
  }
  return { ... plateDefaults, ...(plateOptions || {}) }
}

export default plateFactory
