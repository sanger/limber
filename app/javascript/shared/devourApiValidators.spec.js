import { validateError, hasExpectedProperties } from './devourApiValidators.js'

describe('validateError', () => {
  it('should return unknown error for falsy response', () => {
    const response = null
    const result = validateError(response)
    expect(result).toEqual({ state: 'invalid', message: 'Unknown error' })
  })

  it('should return formatted error for response with title and detail', () => {
    const response = [{ title: 'Test Error', detail: 'This is a test error' }]
    const result = validateError(response)
    expect(result).toEqual({ state: 'invalid', message: 'Test Error: This is a test error' })
  })

  it('should return response with state invalid for other responses', () => {
    const response = { someKey: 'someValue' }
    const result = validateError(response)
    expect(result).toEqual({ ...response, state: 'invalid' })
  })
})

describe('hasExpectedProperties', () => {
  it('should return no results retrieved for empty results', () => {
    const results = []
    const expectedProperties = ['prop1', 'prop2']
    const validator = hasExpectedProperties(expectedProperties)
    const result = validator(results)
    expect(result).toEqual({ valid: false, message: 'No results retrieved' })
  })

  it('should return results objects do not contain expected properties for missing properties', () => {
    const results = [{ prop1: 'value1' }]
    const expectedProperties = ['prop1', 'prop2']
    const validator = hasExpectedProperties(expectedProperties)
    const result = validator(results)
    expect(result).toEqual({ valid: false, message: 'Results objects do not contain expected properties' })
  })

  it('should return results valid for results with all expected properties', () => {
    const results = [{ prop1: 'value1', prop2: 'value2' }]
    const expectedProperties = ['prop1', 'prop2']
    const validator = hasExpectedProperties(expectedProperties)
    const result = validator(results)
    expect(result).toEqual({ valid: true, message: 'Results valid' })
  })
})
