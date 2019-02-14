import { calculateTagLayout } from './tagLayoutFunctions'
import { wellNameToCoordinate } from 'shared/wellHelpers'

describe('calculateTagLayout', () => {

  const inputWells = [
    { position: 'A1', aliquotCount: 1, poolId: 1 },
    { position: 'B1', aliquotCount: 1, poolId: 1 },
    { position: 'C1', aliquotCount: 1, poolId: 1 },
    { position: 'A2', aliquotCount: 1, poolId: 2 },
    { position: 'B2', aliquotCount: 1, poolId: 1 },
    { position: 'C2', aliquotCount: 1, poolId: 2 },
    { position: 'A3', aliquotCount: 1, poolId: 1 },
    { position: 'B3', aliquotCount: 1, poolId: 1 },
    { position: 'C3', aliquotCount: 1, poolId: 1 },
    { position: 'A4', aliquotCount: 1, poolId: 1 },
    { position: 'C4', aliquotCount: 1, poolId: 1 }
  ]

  const tagGrp1 = {
    id: '1',
    name: 'Tag Group 1',
    tags: [
      { index: 1, oligo: 'ACTGAAAA' },
      { index: 2, oligo: 'ACTGAAAT' },
      { index: 3, oligo: 'ACTGAAAG' },
      { index: 4, oligo: 'ACTGAAAC' },
      { index: 5, oligo: 'ACTGAATA' },
      { index: 6, oligo: 'ACTGAATG' },
      { index: 7, oligo: 'ACTGAATC' },
      { index: 8, oligo: 'ACTGAATT' },
      { index: 9, oligo: 'ACTGAAGA' },
      { index: 10, oligo: 'ACTGAAGT' },
      { index: 11, oligo: 'ACTGAAGC' },
      { index: 12, oligo: 'ACTGAAGG' }
    ]
  }

  const tagGrp2 = {
    id: '2',
    name: 'Tag Group 2',
    tags: [
      { index: 1, oligo: 'GCTGAAAA' },
      { index: 2, oligo: 'GCTGAAAT' },
      { index: 3, oligo: 'GCTGAAAG' },
      { index: 4, oligo: 'GCTGAAAC' },
      { index: 5, oligo: 'GCTGAATA' },
      { index: 6, oligo: 'GCTGAATG' },
      { index: 7, oligo: 'GCTGAATC' },
      { index: 8, oligo: 'GCTGAATT' },
      { index: 9, oligo: 'GCTGAAGA' },
      { index: 10, oligo: 'GCTGAAGT' },
      { index: 11, oligo: 'GCTGAAGC' },
      { index: 12, oligo: 'GCTGAAGG' }
    ]
  }

  it('builds the wells to tag index array for sequential plate by column', () => {
    const outputWells = { 'A1': 1, 'B1': 2, 'C1': 3, 'A2': 4, 'B2': 5, 'C2': 6, 'A3': 7, 'B3': 8, 'C3': 9, 'A4': 10, 'C4': 11 }
    const plateDims = { number_of_rows: 3, number_of_columns: 4 }
    const response = calculateTagLayout(inputWells, plateDims, tagGrp1, tagGrp2, 'by_plate_seq', 'by_columns', 0)

    expect(response).toEqual(outputWells)
  })

  it('builds the wells to tag index array for sequential plate by row', () => {
    const outputWells = { 'A1': 1, 'B1': 5, 'C1': 8, 'A2': 2, 'B2': 6, 'C2': 9, 'A3': 3, 'B3': 7, 'C3': 10, 'A4': 4, 'C4': 11 }
    const plateDims = { number_of_rows: 3, number_of_columns: 4 }
    const response = calculateTagLayout(inputWells, plateDims, tagGrp1, tagGrp2, 'by_plate_seq', 'by_rows', 0)

    expect(response).toEqual(outputWells)
  })

  it('builds the wells to tag index array for fixed plate by column', () => {
    const outputWells = { 'A1': 1, 'B1': 2, 'C1': 3, 'A2': 4, 'B2': 5, 'C2': 6, 'A3': 7, 'B3': 8, 'C3': 9, 'A4': 10, 'C4': 12 }
    const plateDims = { number_of_rows: 3, number_of_columns: 4 }
    const response = calculateTagLayout(inputWells, plateDims, tagGrp1, tagGrp2, 'by_plate_fixed', 'by_columns', 0)

    expect(response).toEqual(outputWells)
  })

  it('builds the wells to tag index array for fixed plate by row', () => {
    const outputWells = { 'A1': 1, 'B1': 5, 'C1': 9, 'A2': 2, 'B2': 6, 'C2': 10, 'A3': 3, 'B3': 7, 'C3': 11, 'A4': 4, 'C4': 12 }
    const plateDims = { number_of_rows: 3, number_of_columns: 4 }
    const response = calculateTagLayout(inputWells, plateDims, tagGrp1, tagGrp2, 'by_plate_fixed', 'by_rows', 0)

    expect(response).toEqual(outputWells)
  })

  it('builds the wells to tag index array for by pool by column', () => {
    const outputWells = { 'A1': 1, 'B1': 2, 'C1': 3, 'A2': 1, 'B2': 4, 'C2': 2, 'A3': 5, 'B3': 6, 'C3': 7, 'A4': 8, 'C4': 9 }
    const plateDims = { number_of_rows: 3, number_of_columns: 4 }
    const response = calculateTagLayout(inputWells, plateDims, tagGrp1, tagGrp2, 'by_pool', 'by_columns', 0)

    expect(response).toEqual(outputWells)
  })

  it('builds the wells to tag index array for by pool by row', () => {
    const outputWells = { 'A1': 1, 'B1': 4, 'C1': 7, 'A2': 1, 'B2': 5, 'C2': 2, 'A3': 2, 'B3': 6, 'C3': 8, 'A4': 3, 'C4': 9 }
    const plateDims = { number_of_rows: 3, number_of_columns: 4 }
    const response = calculateTagLayout(inputWells, plateDims, tagGrp1, tagGrp2, 'by_pool', 'by_rows', 0)

    expect(response).toEqual(outputWells)
  })

  // offsets for all 6 scenarios above (nb. need more tags in tag group)

  // tag group 2 instead of 1 (null)

  // tag group tags do not start with index 1

  // tag group tags do not start with index 1 and have gaps in numbering


})