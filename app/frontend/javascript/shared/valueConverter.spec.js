// // Import the component being tested
import valueConverter from './valueConverter'

describe('valueConverter', () => {
  it('converts values in an object using the provided function', () => {
    let object = { a: 1, b: 2, c: 3 }

    expect(valueConverter(object, (value) => value.toString())).toEqual({
      a: '1',
      b: '2',
      c: '3',
    })

    expect(object).toEqual({ a: 1, b: 2, c: 3 })
  })
})
