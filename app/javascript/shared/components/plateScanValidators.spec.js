import { substractArrays, checkLibraryTypesInAllWells, checkSize, checkDuplicates, checkExcess, checkState, checkQCableWalkingBy } from 'shared/components/plateScanValidators'

describe('checkSize', () => {
  it('is valid if the plate is the correct size', () => {
    expect(
      checkSize(12,8)({number_of_columns: 12, number_of_rows: 8 })
    ).toEqual({ valid: true })
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
      checkDuplicates([plate1, plate2])(plate1)
    ).toEqual({ valid: true })
  })

  it('fails if there are duplicate plates', () => {
    const plate1 = { uuid: 'plate-uuid-1' }

    expect(
      checkDuplicates([plate1, plate1])(plate1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  xit('fails if there are duplicate plates even when the parent has not been updated', () => {
    // We emit the plate and state as a single event, and want to avoid the situation
    // where plates flick from valid to invalid
    const empty  = null
    const plate1 = { uuid: 'plate-uuid-1' }

    expect(
      checkDuplicates([empty, plate1])(plate1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  it('passes if it has distinct plates and the parent has not been updated', () => {
    const empty  = null
    const plate1 = { uuid: 'plate-uuid-1' }
    const plate2 = { uuid: 'plate-uuid-2' }

    expect(
      checkDuplicates([empty, plate2])(plate1)
    ).toEqual({ valid: true })
  })
})

describe('checkExcess', () => {
  it('passes when the plate is not the source of excess transfers', () => {
    const plate = { uuid: 'plate-uuid-1' }
    const other_plate = { uuid: 'plate-uuid-2' }
    const excessTransfers = [{
      plateObj: { plate: other_plate }
    }]

    expect(
      checkExcess(excessTransfers)(plate)
    ).toEqual({ valid: true })
  })

  it('fails when the plate is the source of excess transfers', () => {
    const plate = { uuid: 'plate-uuid-1' }
    const excessTransfers = [{
      plateObj: { plate: plate },
      well: { position: { name: 'D11' } }
    },
    {
      plateObj: { plate: plate },
      well: { position: { name: 'D12' } }
    }]

    expect(
      checkExcess(excessTransfers)(plate)
    ).toEqual({ valid: false, message: 'Wells in excess: D11, D12' })
  })
})

describe('checkState', () => {
  it('passes if the state is in the allowed list', () => {
    const plate = { state: 'available' }

    expect(
      checkState(['available', 'exhausted'],0)(plate)
    ).toEqual({ valid: true })
  })

  it('fails if the state is not in the allowed list', () => {
    const plate = { state: 'destroyed' }

    expect(
      checkState(['available', 'exhausted'],0)(plate)
    ).toEqual({ valid: false, message: 'Plate must have a state of: available or exhausted' })
  })
})

describe('checkQCableWalkingBy', () => {
  it('passes if the walking by is in the allowed list', () => {
    const qcable = {
      lot: {
        tag_layout_template: {
          walking_by: 'wells of plate'
        }
      }
    }

    expect(
      checkQCableWalkingBy(['wells of plate'],0)(qcable)
    ).toEqual({ valid: true })
  })

  it('fails if the qcable does not contain a tag layout template', () => {
    const qcable = {
      lot: {}
    }

    expect(
      checkQCableWalkingBy(['pool', 'plate sequential'],0)(qcable)
    ).toEqual({ valid: false, message: 'QCable should have a tag layout template and walking by' })
  })

  it('fails if the walking by is not in the allowed list', () => {
    const qcable = {
      lot: {
        tag_layout_template: {
          walking_by: 'wells of plate'
        }
      }
    }

    expect(
      checkQCableWalkingBy(['pool', 'plate sequential'],0)(qcable)
    ).toEqual({ valid: false, message: 'QCable layout must have a walking by of: pool or plate sequential' })
  })

  describe('substractArrays', () => {
    it('can substract arrays', () => {
      expect(substractArrays([1,2,3], [2,3])).toEqual([1])
      expect(substractArrays([1,2,3], [1,2,3])).toEqual([])
      expect(substractArrays([1,2,3], [])).toEqual([1,2,3])
      expect(substractArrays([], [1,2,3])).toEqual([])
      expect(substractArrays([], [])).toEqual([])
    })
  })

  describe('checkLibraryTypesInAllWells', () => {
    describe('when we have all libraries for every position', () => {
      const plate = {
        wells: [
          { position: { name: 'A1' }, requests_as_source: [ {library_type: 'A'}, {library_type: 'B'}]},
          { position: {name: 'B1'}, requests_as_source: [{library_type: 'A'}, {library_type: 'B'}]}
        ]
      }
      // const transfers = [
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'A'}, plateObj: {index: 0} },
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'B'}, plateObj: {index: 0} },
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'A'}, plateObj: {index: 1} },
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'B'}, plateObj: {index: 1} },
      //   { well: {position: {name: 'B1'}}, request: { library_type: 'A'}, plateObj: {index: 0} },
      //   { well: {position: {name: 'B1'}}, request: { library_type: 'B'}, plateObj: {index: 0} }
      // ]
      const validator = checkLibraryTypesInAllWells(['A', 'B'])

      it('validates that the library types are present in all wells', () => {
        expect(validator(plate)).toEqual({ valid: true })
      })
    })

    describe('when we are missing libraries in one of the positions', () => {
      const plate = {
        wells: [
          {position: {name: 'A1'}, requests_as_source: [{library_type: 'A'}, {library_type: 'B'}]},
          {position: {name: 'B1'}, requests_as_source: [{library_type: 'A'}]}
        ]
      }

      // const transfers = [
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'A'}, plateObj: {index: 0} },
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'B'}, plateObj: {index: 0} },
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'A'}, plateObj: {index: 1} },
      //   { well: {position: {name: 'A1'}}, request: { library_type: 'B'}, plateObj: {index: 1} },
      //   { well: {position: {name: 'B1'}}, request: { library_type: 'A'}, plateObj: {index: 0} },
      // ]
      const validator = checkLibraryTypesInAllWells(['A', 'B'])
      it('displays the error message for that position', () => {
        expect(validator(plate)).toEqual(
          { valid: false, 
            message: 'The well at position B1 is missing libraries: B'
          })
      })
    })
  })
})
