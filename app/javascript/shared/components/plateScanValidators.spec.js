// // Import the component being tested
import { checkSize, checkDuplicates, checkOverflows, aggregate } from './plateScanValidators'

describe('aggregate', () => {
  const validFunction = (_) => { return { valid: true, message: 'Good' } }
  const invalidFunction = (_) => { return { valid: false, message: 'Bad' } }

  it('is valid if all functions are valid', () => {
    expect(aggregate(validFunction, validFunction)('')).toEqual({ valid: true, message: 'Good' })
  })

  it('is invalid if any functions are invalid', () => {
    expect(aggregate(validFunction, invalidFunction)('')).toEqual({ valid: false, message: 'Bad' })
    expect(aggregate(invalidFunction, validFunction)('')).toEqual({ valid: false, message: 'Bad' })
  })
})

describe('checkSize', () => {
  it('is valid if the plate is the correct size', () => {
    expect(
      checkSize(12,8)({number_of_columns: 12, number_of_rows: 8 })
    ).toEqual({ valid: true, message: 'Great!' })
  })

  it('is valid if the plate is the wrong size', () => {
    expect(
      checkSize(12,8)({number_of_columns: 24, number_of_rows: 16 })
    ).toEqual({ valid: false, message: 'The plate should be 12×8 wells in size' })
  })
})

describe('checkDuplicates', () => {
  it('passes if it has distinct plates', () => {
    const plate1 = { uuid: 'plate-uuid-1' }
    const plate2 = { uuid: 'plate-uuid-2' }

    expect(
      checkDuplicates([plate1,plate2],0)(plate1)
    ).toEqual({ valid: true, message: 'Great!' })
  })

  it('fails if there are duplicate plates', () => {
    const plate1 = { uuid: 'plate-uuid-1' }

    expect(
      checkDuplicates([plate1,plate1],0)(plate1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  it('fails if there are duplicate plates even when the parent has not been updated', () => {
    // We emit the plate and state as a single event, and want to avoid the situation
    // where plates flick from valid to invalid
    const empty  = null
    const plate1 = { uuid: 'plate-uuid-1' }

    expect(
      checkDuplicates([empty,plate1],0)(plate1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  it('passes if it has distinct plates and the parent has not been updated', () => {
    const empty  = null
    const plate1 = { uuid: 'plate-uuid-1' }
    const plate2 = { uuid: 'plate-uuid-2' }

    expect(
      checkDuplicates([empty,plate2],0)(plate1)
    ).toEqual({ valid: true, message: 'Great!' })
  })
})

describe('checkOverflows', () => {
  it('passes when the plate is not the source of transfers that overflow the target', () => {
    const plate = { uuid: 'plate-uuid-1' }
    const other_plate = { uuid: 'plate-uuid-2' }
    const overflownTransfers = [{
      plateObj: { plate: other_plate }
    }]

    expect(
      checkOverflows(overflownTransfers)(plate)
    ).toEqual({ valid: true, message: 'Great!' })
  })

  it('fails when the plate is the source of transfers that overflow the target', () => {
    const plate = { uuid: 'plate-uuid-1' }
    const overflownTransfers = [{
      plateObj: { plate: plate },
      well: { position: { name: 'D11' } }
    },
    {
      plateObj: { plate: plate },
      well: { position: { name: 'D12' } }
    }]

    expect(
      checkOverflows(overflownTransfers)(plate)
    ).toEqual({ valid: false, message: 'Overflown wells: D11, D12' })
  })
})
