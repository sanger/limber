// // Import the component being tested
import { includeUnion, fieldsUnion } from './jsonIncludeHelpers'

describe('includeUnion', () => {

  const include1 = 'typeA,typeA.thing,typeC'
  const include2 = 'typeD,typeD.thing'
  const include3 = 'typeA.thing,typeE'

  it('returns a combination of two include strings', () => {
    expect(includeUnion([include1,include2])).toEqual('typeA,typeA.thing,typeC,typeD,typeD.thing')
  })

  it('returns a combination of three include strings with filters removed', () => {
    expect(includeUnion([include1,include2,include3])).toEqual('typeA,typeA.thing,typeC,typeD,typeD.thing,typeE')
  })
})


describe('filedsUnion', () => {

  const fields1 = {
    typeA: 'valA,valB',
    typeB: 'valA,valB'
  }
  const fields2 = {
    typeC: 'valA,valB'
  }
  const fields3 = {
    typeA: 'valC',
    typeC: 'valA,valC'
  }

  it('returns a combination of two fields objects', () => {
    expect(fieldsUnion([fields1,fields2])).toEqual({
      typeA: 'valA,valB',
      typeB: 'valA,valB',
      typeC: 'valA,valB'
    })
  })

  it('returns a combination of three fields objects with filters removed', () => {
    expect(fieldsUnion([fields1,fields2,fields3])).toEqual({
      typeA: 'valA,valB,valC',
      typeB: 'valA,valB',
      typeC: 'valA,valB,valC'
    })
  })
})
