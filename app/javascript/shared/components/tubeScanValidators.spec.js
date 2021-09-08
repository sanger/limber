import { checkDuplicates, checkState, aggregate } from 'shared/components/tubeScanValidators'

describe('aggregate', () => {
  const validFunction = (_) => { return { valid: true, message: 'Good' } }
  const invalidFunction = (_) => { return { valid: false, message: 'Bad' } }

  it('is valid if all functions are valid', () => {
    expect(aggregate([validFunction, validFunction], {})).toEqual({ valid: true, message: 'Good' })
  })

  it('is invalid if any functions are invalid', () => {
    expect(aggregate([validFunction, invalidFunction], {})).toEqual({ valid: false, message: 'Bad' })
    expect(aggregate([invalidFunction, validFunction], {})).toEqual({ valid: false, message: 'Bad' })
  })
})

describe('checkDuplicates', () => {
  it('passes if it has distinct tubes', () => {
    const tube1 = { uuid: 'tube-uuid-1' }
    const tube2 = { uuid: 'tube-uuid-2' }

    expect(
      checkDuplicates([tube1, tube2])(tube1)
    ).toEqual({ valid: true, message: 'Great!' })
  })

  it('fails if there are duplicate tubes', () => {
    const tube1 = { uuid: 'tube-uuid-1' }

    expect(
      checkDuplicates([tube1, tube1])(tube1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  xit('fails if there are duplicate tubes even when the parent has not been updated', () => {
    // We emit the tube and state as a single event, and want to avoid the situation
    // where tubes flick from valid to invalid
    const empty  = null
    const tube1 = { uuid: 'tube-uuid-1' }

    expect(
      checkDuplicates([empty, tube1])(tube1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  it('passes if it has distinct tubes and the parent has not been updated', () => {
    const empty  = null
    const tube1 = { uuid: 'tube-uuid-1' }
    const tube2 = { uuid: 'tube-uuid-2' }

    expect(
      checkDuplicates([empty, tube2])(tube1)
    ).toEqual({ valid: true, message: 'Great!' })
  })
})

describe('checkState', () => {
  it('passes if the state is in the allowed list', () => {
    const tube = { state: 'available' }

    expect(
      checkState(['available', 'exhausted'],0)(tube)
    ).toEqual({ valid: true, message: 'Great!' })
  })

  it('fails if the state is not in the allowed list', () => {
    const tube = { state: 'destroyed' }

    expect(
      checkState(['available', 'exhausted'],0)(tube)
    ).toEqual({ valid: false, message: 'Tube must have a state of: available or exhausted' })
  })
})
