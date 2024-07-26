import { aggregate, validScanMessage } from '@/javascript/shared/components/scanValidators.js'

describe('aggregate', () => {
  const validFunction = (_) => {
    return { valid: true, message: 'Good' }
  }
  const invalidFunction = (_) => {
    return { valid: false, message: 'Bad' }
  }

  it('is valid if all functions are valid', () => {
    expect(aggregate([validFunction, validFunction], {})).toEqual({
      valid: true,
      message: 'Good',
    })
  })

  it('is invalid if any functions are invalid', () => {
    expect(aggregate([validFunction, invalidFunction], {})).toEqual({
      valid: false,
      message: 'Bad',
    })
    expect(aggregate([invalidFunction, validFunction], {})).toEqual({
      valid: false,
      message: 'Bad',
    })
  })
})

describe('validScanMessage', () => {
  it('provides a valid scan result object', () => {
    expect(validScanMessage()).toEqual({ valid: true })
  })
})
