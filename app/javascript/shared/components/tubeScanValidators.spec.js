import { checkDuplicates, checkMatchingPurposes, checkState } from 'shared/components/tubeScanValidators'

describe('checkDuplicates', () => {
  it('passes if it has distinct tubes', () => {
    const tube1 = { uuid: 'tube-uuid-1' }
    const tube2 = { uuid: 'tube-uuid-2' }

    expect(
      checkDuplicates([tube1, tube2])(tube1)
    ).toEqual({ valid: true })
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
    ).toEqual({ valid: true })
  })
})

describe('checkMatchingPurposes', () => {
  it('passes if the tube has a matching purpose', () => {
    const tube = { purpose: { name: 'A Purpose' } }
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube)).toEqual({ valid: true })
  })

  it('passes if the tube is undefined', () => {
    const tube = undefined
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube)).toEqual({ valid: true })
  })

  it('passes if the reference purpose is undefined', () => {
    const tube = { purpose: { name: 'A Purpose' } }
    expect(checkMatchingPurposes(undefined)(tube)).toEqual({ valid: true })
  })

  it('fails if the tube purpose is undefined', () => {
    const tube = {}
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube))
      .toEqual({ valid: false, message: 'Tube purpose \'UNKNOWN\' doesn\'t match other tubes' })
  })

  it('fails if the tube purpose doesn\'t match the reference purpose', () => {
    const tube = { purpose: { name: 'Another Purpose' } }
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube))
      .toEqual({ valid: false, message: 'Tube purpose \'Another Purpose\' doesn\'t match other tubes' })
  })
})

describe('checkState', () => {
  it('passes if the state is in the allowed list', () => {
    const tube = { state: 'available' }

    expect(
      checkState(['available', 'exhausted'],0)(tube)
    ).toEqual({ valid: true })
  })

  it('fails if the state is not in the allowed list', () => {
    const tube = { state: 'destroyed' }

    expect(
      checkState(['available', 'exhausted'],0)(tube)
    ).toEqual({ valid: false, message: 'Tube must have a state of: available or exhausted' })
  })
})
