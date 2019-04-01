import { calculateTagLayout } from './tagLayoutFunctions'

describe('calculateTagLayout', () => {

  const inputWells = [
    { position: 'A1', aliquotCount: 1, pool_index: 1 },
    { position: 'B1', aliquotCount: 1, pool_index: 1 },
    { position: 'C1', aliquotCount: 1, pool_index: 1 },
    { position: 'A2', aliquotCount: 1, pool_index: 2 },
    { position: 'B2', aliquotCount: 1, pool_index: 1 },
    { position: 'C2', aliquotCount: 1, pool_index: 2 },
    { position: 'A3', aliquotCount: 1, pool_index: 1 },
    { position: 'B3', aliquotCount: 1, pool_index: 1 },
    { position: 'C3', aliquotCount: 1, pool_index: 1 },
    { position: 'A4', aliquotCount: 1, pool_index: 1 },
    { position: 'B4', aliquotCount: 0 },
    { position: 'C4', aliquotCount: 1, pool_index: 1 }
  ]
  const tagMapIdsStandard  = Array.from(new Array(96), (x,i) => i + 1) // [1,2,..96]
  const tagMapIdsNonConseq = [ 2,5,6,7,9,10,12,13,14,15,17,18 ]
  const tagMapIdsShort     = [ 1,2,3,4,5,6 ]
  const tagMapIdsEmpty     = []

  const plateDims = { number_of_rows: 3, number_of_columns: 4 }

  describe('validations: ', () => {
    it('returns empty object if no tag groups are supplied', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: null,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual({})
    })

    it('returns empty object if tag map ids is empty', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsEmpty,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual({})
    })

    it('returns empty object if no input wells are supplied', () => {
      const data = {
        wells: null,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual({})
    })

    it('returns empty object if no plate dimensions are supplied', () => {
      const data = {
        wells: inputWells,
        plateDims: null,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual({})
    })

    it('returns empty object if invalid plate dimensions are supplied', () => {
      const invalidPlateDims = { number_of_rows: 0, number_of_columns: 4 }
      const data = {
        wells: inputWells,
        plateDims: invalidPlateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual({})
    })
  })

  describe('sequential plate layouts: ', () => {
    it('sequential by column', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 2 ],
        'C1': [ 3 ],
        'A2': [ 4 ],
        'B2': [ 5 ],
        'C2': [ 6 ],
        'A3': [ 7 ],
        'B3': [ 8 ],
        'C3': [ 9 ],
        'A4': [ 10 ],
        'C4': [ 11 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by row', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'row',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 5 ],
        'C1': [ 8 ],
        'A2': [ 2 ],
        'B2': [ 6 ],
        'C2': [ 9 ],
        'A3': [ 3 ],
        'B3': [ 7 ],
        'C3': [ 10 ],
        'A4': [ 4 ],
        'C4': [ 11 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 5 ],
        'B1': [ 6 ],
        'C1': [ 7 ],
        'A2': [ 8 ],
        'B2': [ 9 ],
        'C2': [ 10 ],
        'A3': [ 11 ],
        'B3': [ 12 ],
        'C3': [ 13 ],
        'A4': [ 14 ],
        'C4': [ 15 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'row',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 5 ],
        'B1': [ 9 ],
        'C1': [ 12 ],
        'A2': [ 6 ],
        'B2': [ 10 ],
        'C2': [ 13 ],
        'A3': [ 7 ],
        'B3': [ 11 ],
        'C3': [ 14 ],
        'A4': [ 8 ],
        'C4': [ 15 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by inverse column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'inverse column',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 15 ],
        'B1': [ 14 ],
        'C1': [ 13 ],
        'A2': [ 12 ],
        'B2': [ 11 ],
        'C2': [ 10 ],
        'A3': [ 9 ],
        'B3': [ 8 ],
        'C3': [ 7 ],
        'A4': [ 6 ],
        'C4': [ 5 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by inverse row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by plate',
        direction: 'inverse row',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 15 ],
        'B1': [ 11 ],
        'C1': [ 8 ],
        'A2': [ 14 ],
        'B2': [ 10 ],
        'C2': [ 7 ],
        'A3': [ 13 ],
        'B3': [ 9 ],
        'C3': [ 6 ],
        'A4': [ 12 ],
        'C4': [ 5 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by column when some wells empty', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsNonConseq,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 2 ],
        'B1': [ 5 ],
        'C1': [ 6 ],
        'A2': [ 7 ],
        'B2': [ 9 ],
        'C2': [ 10 ],
        'A3': [ 12 ],
        'B3': [ 13 ],
        'C3': [ 14 ],
        'A4': [ 15 ],
        'C4': [ 17 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by column where not enough tags', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsShort,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 2 ],
        'C1': [ 3 ],
        'A2': [ 4 ],
        'B2': [ 5 ],
        'C2': [ 6 ],
        'A3': [ -1 ],
        'B3': [ -1 ],
        'C3': [ -1 ],
        'A4': [ -1 ],
        'C4': [ -1 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })
  })

  describe('fixed plate layouts: ', () => {
    it('fixed by column', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 2 ],
        'C1': [ 3 ],
        'A2': [ 4 ],
        'B2': [ 5 ],
        'C2': [ 6 ],
        'A3': [ 7 ],
        'B3': [ 8 ],
        'C3': [ 9 ],
        'A4': [ 10 ],
        'C4': [ 12 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by row', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'row',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 5 ],
        'C1': [ 9 ],
        'A2': [ 2 ],
        'B2': [ 6 ],
        'C2': [ 10 ],
        'A3': [ 3 ],
        'B3': [ 7 ],
        'C3': [ 11 ],
        'A4': [ 4 ],
        'C4': [ 12 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by inverse column', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'inverse column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 12 ],
        'B1': [ 11 ],
        'C1': [ 10 ],
        'A2': [ 9 ],
        'B2': [ 8 ],
        'C2': [ 7 ],
        'A3': [ 6 ],
        'B3': [ 5 ],
        'C3': [ 4 ],
        'A4': [ 3 ],
        'C4': [ 1 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by inverse row', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'inverse row',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 12 ],
        'B1': [ 8 ],
        'C1': [ 4 ],
        'A2': [ 11 ],
        'B2': [ 7 ],
        'C2': [ 3 ],
        'A3': [ 10 ],
        'B3': [ 6 ],
        'C3': [ 2 ],
        'A4': [ 9 ],
        'C4': [ 1 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'column',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 5 ],
        'B1': [ 6 ],
        'C1': [ 7 ],
        'A2': [ 8 ],
        'B2': [ 9 ],
        'C2': [ 10 ],
        'A3': [ 11 ],
        'B3': [ 12 ],
        'C3': [ 13 ],
        'A4': [ 14 ],
        'C4': [ 16 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'row',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 5 ],
        'B1': [ 9 ],
        'C1': [ 13 ],
        'A2': [ 6 ],
        'B2': [ 10 ],
        'C2': [ 14 ],
        'A3': [ 7 ],
        'B3': [ 11 ],
        'C3': [ 15 ],
        'A4': [ 8 ],
        'C4': [ 16 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by inverse column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'inverse column',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 16 ],
        'B1': [ 15 ],
        'C1': [ 14 ],
        'A2': [ 13 ],
        'B2': [ 12 ],
        'C2': [ 11 ],
        'A3': [ 10 ],
        'B3': [ 9 ],
        'C3': [ 8 ],
        'A4': [ 7 ],
        'C4': [ 5 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('fixed by inverse row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'wells of plate',
        direction: 'inverse row',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 16 ],
        'B1': [ 12 ],
        'C1': [ 8 ],
        'A2': [ 15 ],
        'B2': [ 11 ],
        'C2': [ 7 ],
        'A3': [ 14 ],
        'B3': [ 10 ],
        'C3': [ 6 ],
        'A4': [ 13 ],
        'C4': [ 5 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })
  })

  describe('pooled plate layouts: ', () => {
    it('pooled by column', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 2 ],
        'C1': [ 3 ],
        'A2': [ 1 ],
        'B2': [ 4 ],
        'C2': [ 2 ],
        'A3': [ 5 ],
        'B3': [ 6 ],
        'C3': [ 7 ],
        'A4': [ 8 ],
        'C4': [ 9 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by row', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'row',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 1 ],
        'B1': [ 4 ],
        'C1': [ 7 ],
        'A2': [ 1 ],
        'B2': [ 5 ],
        'C2': [ 2 ],
        'A3': [ 2 ],
        'B3': [ 6 ],
        'C3': [ 8 ],
        'A4': [ 3 ],
        'C4': [ 9 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by inverse column', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'inverse column',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 9 ],
        'B1': [ 8 ],
        'C1': [ 7 ],
        'A2': [ 2 ],
        'B2': [ 6 ],
        'C2': [ 1 ],
        'A3': [ 5 ],
        'B3': [ 4 ],
        'C3': [ 3 ],
        'A4': [ 2 ],
        'C4': [ 1 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by inverse row', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'inverse row',
        offsetTagsBy: 0,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 9 ],
        'B1': [ 6 ],
        'C1': [ 3 ],
        'A2': [ 2 ],
        'B2': [ 5 ],
        'C2': [ 1 ],
        'A3': [ 8 ],
        'B3': [ 4 ],
        'C3': [ 2 ],
        'A4': [ 7 ],
        'C4': [ 1 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'column',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 5 ],
        'B1': [ 6 ],
        'C1': [ 7 ],
        'A2': [ 5 ],
        'B2': [ 8 ],
        'C2': [ 6 ],
        'A3': [ 9 ],
        'B3': [ 10 ],
        'C3': [ 11 ],
        'A4': [ 12 ],
        'C4': [ 13 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'row',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 5 ],
        'B1': [ 8 ],
        'C1': [ 11 ],
        'A2': [ 5 ],
        'B2': [ 9 ],
        'C2': [ 6 ],
        'A3': [ 6 ],
        'B3': [ 10 ],
        'C3': [ 12 ],
        'A4': [ 7 ],
        'C4': [ 13 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by inverse column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'inverse column',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 13 ],
        'B1': [ 12 ],
        'C1': [ 11 ],
        'A2': [ 6 ],
        'B2': [ 10 ],
        'C2': [ 5 ],
        'A3': [ 9 ],
        'B3': [ 8 ],
        'C3': [ 7 ],
        'A4': [ 6 ],
        'C4': [ 5 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('pooled by inverse row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'manual by pool',
        direction: 'inverse row',
        offsetTagsBy: 4,
        tagsPerWell: 1
      }
      const outputWells = {
        'A1': [ 13 ],
        'B1': [ 10 ],
        'C1': [ 7 ],
        'A2': [ 6 ],
        'B2': [ 9 ],
        'C2': [ 5 ],
        'A3': [ 12 ],
        'B3': [ 8 ],
        'C3': [ 6 ],
        'A4': [ 11 ],
        'C4': [ 5 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })
  })

  describe('as multiple tags per well (e.g. chromium): ', () => {
    it('by column', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'as group by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [ 1,2,3,4 ],
        'B1': [ 5,6,7,8 ],
        'C1': [ 9,10,11,12 ],
        'A2': [ 13,14,15,16 ],
        'B2': [ 17,18,19,20 ],
        'C2': [ 21,22,23,24 ],
        'A3': [ 25,26,27,28 ],
        'B3': [ 29,30,31,32 ],
        'C3': [ 33,34,35,36 ],
        'A4': [ 37,38,39,40 ],
        'C4': [ 41,42,43,44 ]
      }

      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('by row', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'as group by plate',
        direction: 'row',
        offsetTagsBy: 0,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [1,2,3,4],
        'B1': [17,18,19,20],
        'C1': [29,30,31,32],
        'A2': [5,6,7,8],
        'B2': [21,22,23,24],
        'C2': [33,34,35,36],
        'A3': [9,10,11,12],
        'B3': [25,26,27,28],
        'C3': [37,38,39,40],
        'A4': [13,14,15,16],
        'C4': [41,42,43,44]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('by column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'as group by plate',
        direction: 'column',
        offsetTagsBy: 4,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [ 17,18,19,20 ],
        'B1': [ 21,22,23,24 ],
        'C1': [ 25,26,27,28 ],
        'A2': [ 29,30,31,32 ],
        'B2': [ 33,34,35,36 ],
        'C2': [ 37,38,39,40 ],
        'A3': [ 41,42,43,44 ],
        'B3': [ 45,46,47,48 ],
        'C3': [ 49,50,51,52 ],
        'A4': [ 53,54,55,56 ],
        'C4': [ 57,58,59,60 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('by row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'as group by plate',
        direction: 'row',
        offsetTagsBy: 4,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [ 17,18,19,20 ],
        'B1': [ 33,34,35,36 ],
        'C1': [ 45,46,47,48 ],
        'A2': [ 21,22,23,24 ],
        'B2': [ 37,38,39,40 ],
        'C2': [ 49,50,51,52 ],
        'A3': [ 25,26,27,28 ],
        'B3': [ 41,42,43,44 ],
        'C3': [ 53,54,55,56 ],
        'A4': [ 29,30,31,32 ],
        'C4': [ 57,58,59,60 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('by inverse column with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'as group by plate',
        direction: 'inverse column',
        offsetTagsBy: 4,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [ 57,58,59,60 ],
        'B1': [ 53,54,55,56 ],
        'C1': [ 49,50,51,52 ],
        'A2': [ 45,46,47,48 ],
        'B2': [ 41,42,43,44 ],
        'C2': [ 37,38,39,40 ],
        'A3': [ 33,34,35,36 ],
        'B3': [ 29,30,31,32 ],
        'C3': [ 25,26,27,28 ],
        'A4': [ 21,22,23,24 ],
        'C4': [ 17,18,19,20 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('by inverse row with offset', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsStandard,
        walkingBy: 'as group by plate',
        direction: 'inverse row',
        offsetTagsBy: 4,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [ 57,58,59,60 ],
        'B1': [ 41,42,43,44 ],
        'C1': [ 29,30,31,32 ],
        'A2': [ 53,54,55,56 ],
        'B2': [ 37,38,39,40 ],
        'C2': [ 25,26,27,28 ],
        'A3': [ 49,50,51,52 ],
        'B3': [ 33,34,35,36 ],
        'C3': [ 21,22,23,24 ],
        'A4': [ 45,46,47,48 ],
        'C4': [ 17,18,19,20 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })

    it('sequential by column where not enough tags available', () => {
      const data = {
        wells: inputWells,
        plateDims: plateDims,
        tagMapIds: tagMapIdsShort,
        walkingBy: 'manual by plate',
        direction: 'column',
        offsetTagsBy: 0,
        tagsPerWell: 4
      }
      const outputWells = {
        'A1': [ 1,2,3,4 ],
        'B1': [ 5,6,-1,-1 ],
        'C1': [ -1,-1,-1,-1 ],
        'A2': [ -1,-1,-1,-1 ],
        'B2': [ -1,-1,-1,-1 ],
        'C2': [ -1,-1,-1,-1 ],
        'A3': [ -1,-1,-1,-1 ],
        'B3': [ -1,-1,-1,-1 ],
        'C3': [ -1,-1,-1,-1 ],
        'A4': [ -1,-1,-1,-1 ],
        'C4': [ -1,-1,-1,-1 ]
      }
      const response = calculateTagLayout(data)

      expect(response).toEqual(outputWells)
    })
  })
})
