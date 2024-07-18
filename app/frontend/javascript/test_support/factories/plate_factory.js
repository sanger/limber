import buildArray from '@/javascript/shared/buildArray'
import { indexToName } from '@/javascript/shared/wellHelpers'
import wellFactory from 'test_support/factories/well_factory'

const plateFactory = function (options = {}) {
  const { _filledWells, _wellOptions, ...plateOptions } = options
  let uuid = plateOptions.uuid || 'plate-uuid'
  let id = plateOptions.id || '1'
  // Bit inefficient, in that we generate wells even if we immediately override them
  const plateDefaults = {
    name: 'Plate DN1S',
    uuid: uuid,
    id: id,
    labware_barcode: {
      ean13_barcode: '1220542971784',
      human_barcode: 'DN1S',
      machine_barcode: '1220542971784',
    },
    number_of_columns: 12,
    number_of_rows: 8,
    state: 'passed',
    wells: buildArray(_filledWells || 96, (iteration) =>
      wellFactory({
        ...{
          uuid: `${uuid}-well-${iteration}`,
          position: { name: indexToName(iteration, 8) },
        },
        ..._wellOptions,
      })
    ),
  }
  return { ...plateDefaults, ...(plateOptions || {}) }
}

export default plateFactory
