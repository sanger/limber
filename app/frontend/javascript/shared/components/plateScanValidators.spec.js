import {
  getAllLibrarySubmissionsWithMatchingStateForPlate,
  checkAllLibraryRequestsWithSameReadySubmissions,
  checkPlateWithSameReadyLibrarySubmissions,
  getAllUniqueLibrarySubmissionReadyIds,
  checkMaxCountRequests,
  checkMinCountRequests,
  checkAllSamplesInColumnsList,
  checkLibraryTypesInAllWells,
  checkSize,
  checkDuplicates,
  checkState,
  checkQCableWalkingBy,
  checkForUnacceptablePlatePurpose,
} from '@/javascript/shared/components/plateScanValidators'

describe('checkSize', () => {
  it('is valid if the plate is the correct size', () => {
    expect(checkSize(12, 8)({ number_of_columns: 12, number_of_rows: 8 })).toEqual({ valid: true })
  })

  it('is valid if the plate is the wrong size', () => {
    expect(checkSize(12, 8)({ number_of_columns: 24, number_of_rows: 16 })).toEqual({
      valid: false,
      message: 'The plate should be 12×8 wells in size',
    })
  })
})

describe('checkDuplicates', () => {
  it('passes if it has distinct plates', () => {
    const plate1 = { uuid: 'plate-uuid-1' }
    const plate2 = { uuid: 'plate-uuid-2' }

    expect(checkDuplicates([plate1, plate2])(plate1)).toEqual({ valid: true })
  })

  it('fails if there are duplicate plates', () => {
    const plate1 = { uuid: 'plate-uuid-1' }

    expect(checkDuplicates([plate1, plate1])(plate1)).toEqual({
      valid: false,
      message: 'Barcode has been scanned multiple times',
    })
  })

  it.skip('fails if there are duplicate plates even when the parent has not been updated', () => {
    // We emit the plate and state as a single event, and want to avoid the situation
    // where plates flick from valid to invalid
    const empty = null
    const plate1 = { uuid: 'plate-uuid-1' }

    expect(checkDuplicates([empty, plate1])(plate1)).toEqual({
      valid: false,
      message: 'Barcode has been scanned multiple times',
    })
  })

  it('passes if it has distinct plates and the parent has not been updated', () => {
    const empty = null
    const plate1 = { uuid: 'plate-uuid-1' }
    const plate2 = { uuid: 'plate-uuid-2' }

    expect(checkDuplicates([empty, plate2])(plate1)).toEqual({ valid: true })
  })
})

describe('checkState', () => {
  it('passes if the state is in the allowed list', () => {
    const plate = { state: 'available' }

    expect(checkState(['available', 'exhausted'], 0)(plate)).toEqual({
      valid: true,
    })
  })

  it('fails if the state is not in the allowed list', () => {
    const plate = { state: 'destroyed' }

    expect(checkState(['available', 'exhausted'], 0)(plate)).toEqual({
      valid: false,
      message: 'Plate must have a state of: available or exhausted',
    })
  })
})

describe('checkQCableWalkingBy', () => {
  it('passes if the walking by is in the allowed list', () => {
    const qcable = {
      lot: {
        tag_layout_template: {
          walking_by: 'wells of plate',
        },
      },
    }

    expect(checkQCableWalkingBy(['wells of plate'], 0)(qcable)).toEqual({
      valid: true,
    })
  })

  it('fails if the qcable does not contain a tag layout template', () => {
    const qcable = {
      lot: {},
    }

    expect(checkQCableWalkingBy(['pool', 'plate sequential'], 0)(qcable)).toEqual({
      valid: false,
      message: 'QCable should have a tag layout template and walking by',
    })
  })

  it('fails if the walking by is not in the allowed list', () => {
    const qcable = {
      lot: {
        tag_layout_template: {
          walking_by: 'wells of plate',
        },
      },
    }

    expect(checkQCableWalkingBy(['pool', 'plate sequential'], 0)(qcable)).toEqual({
      valid: false,
      message: 'QCable layout must have a walking by of: pool or plate sequential',
    })
  })
})

describe('checkMaxCountRequests', () => {
  const plate_good = {
    wells: [
      { position: { name: 'A1' }, requests_as_source: [{ library_type: 'A' }] },
      { position: { name: 'B1' }, requests_as_source: [{ library_type: 'A' }] },
      { position: { name: 'C1' }, requests_as_source: [] },
    ],
  }
  const plate_bad = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
      {
        position: { name: 'C1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
    ],
  }

  const validator = checkMaxCountRequests(2)

  it('validates has maximum requests', () => {
    expect(validator(plate_good)).toEqual({ valid: true })
  })
  it('fails when has more than maximum requests', () => {
    expect(validator(plate_bad).valid).toEqual(false)
  })
})

describe('checkMinCountRequests', () => {
  const plate_bad = {
    wells: [
      { position: { name: 'A1' }, requests_as_source: [{ library_type: 'A' }] },
      { position: { name: 'B1' }, requests_as_source: [{ library_type: 'A' }] },
      { position: { name: 'C1' }, requests_as_source: [] },
    ],
  }
  const plate_good = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
      {
        position: { name: 'C1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
    ],
  }

  const validator = checkMinCountRequests(3)

  it('validates has more than minimum requests', () => {
    expect(validator(plate_good)).toEqual({ valid: true })
  })
  it('fails when has less than minimum requests', () => {
    expect(validator(plate_bad).valid).toEqual(false)
  })
})

describe('checkAllSamplesInColumnsList', () => {
  const plate_good = {
    wells: [
      { position: { name: 'A1' }, requests_as_source: [{ library_type: 'A' }] },
      { position: { name: 'B2' }, requests_as_source: [{ library_type: 'A' }] },
      { position: { name: 'A3' }, requests_as_source: [{ library_type: 'A' }] },
    ],
  }
  const plate_bad = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
      {
        position: { name: 'A3' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
      {
        position: { name: 'B4' },
        requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
      },
    ],
  }

  const validator = checkAllSamplesInColumnsList(['1', '2', '3'])

  it('validates has samples in valid columns', () => {
    expect(validator(plate_good)).toEqual({ valid: true })
  })
  it('fails when has samples in invalid columns', () => {
    expect(validator(plate_bad).valid).toEqual(false)
  })
})

describe('checkLibraryTypesInAllWells', () => {
  describe('when we have all libraries for every position', () => {
    const plate = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
        },
      ],
    }
    const validator = checkLibraryTypesInAllWells(['A', 'B'])

    it('validates that the library types are present in all wells', () => {
      expect(validator(plate)).toEqual({ valid: true })
    })
  })
  describe('when we have positions without requests', () => {
    const plate = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
        },
        { position: { name: 'C1' }, requests_as_source: [] },
      ],
    }
    const validator = checkLibraryTypesInAllWells(['A', 'B'])

    it('validates that the library types are present in all wells with requests', () => {
      expect(validator(plate)).toEqual({ valid: true })
    })
  })

  describe('when we are missing libraries in one of the positions', () => {
    const plate = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [{ library_type: 'A' }, { library_type: 'B' }],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [{ library_type: 'A' }],
        },
      ],
    }

    const validator = checkLibraryTypesInAllWells(['A', 'B'])
    it('displays the error message for that position', () => {
      expect(validator(plate)).toEqual({
        valid: false,
        message: 'The well at position B1 is missing libraries: B',
      })
    })
  })
})

describe('getAllLibrarySubmissionsWithMatchingStateForPlate', () => {
  const plate = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'failed', id: '1' },
          },
          {
            state: 'pending',
            library_type: 'B',
            submission: { state: 'ready', id: '2' },
          },
        ],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [
          {
            state: 'pending',
            submission: { state: 'ready', id: '2' },
            library_type: 'A',
          },
        ],
      },
    ],
  }
  const plate2 = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'failed', id: '1' },
          },
          {
            state: 'pending',
            library_type: 'B',
            submission: { state: 'ready', id: '2' },
          },
        ],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [
          {
            state: 'pending',
            submission: { state: 'ready', id: '2' },
            library_type: 'A',
          },
        ],
      },
      { position: { name: 'C1' }, requests_as_source: [] },
    ],
  }

  it('returns all submissions with state', () => {
    expect(getAllLibrarySubmissionsWithMatchingStateForPlate(plate, 'ready')).toEqual([['2'], ['2']])
    expect(getAllLibrarySubmissionsWithMatchingStateForPlate(plate, 'failed')).toEqual([['1'], []])
  })

  it('filters out wells without requests', () => {
    expect(getAllLibrarySubmissionsWithMatchingStateForPlate(plate2, 'ready')).toEqual([['2'], ['2']])
    expect(getAllLibrarySubmissionsWithMatchingStateForPlate(plate, 'failed')).toEqual([['1'], []])
  })
})

describe('getAllUniqueLibrarySubmissionReadyIds', () => {
  const plate = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'failed', id: '1' },
          },
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'ready', id: '2' },
          },
        ],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [
          {
            state: 'pending',
            submission: { state: 'ready', id: '3' },
            library_type: 'A',
          },
        ],
      },
    ],
  }

  it('returns all unique submissions with ready state', () => {
    expect(getAllUniqueLibrarySubmissionReadyIds(plate)).toEqual(['2', '3'])
  })
})

describe('checkAllLibraryRequestsWithSameReadySubmissions', () => {
  const plate = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'failed', id: '1' },
          },
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'ready', id: '2' },
          },
          {
            state: 'pending',
            library_type: 'B',
            submission: { state: 'ready', id: '3' },
          },
        ],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [
          {
            state: 'pending',
            submission: { state: 'ready', id: '3' },
            library_type: 'B',
          },
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'ready', id: '2' },
          },
        ],
      },
    ],
  }

  const plate2 = {
    wells: [
      {
        position: { name: 'A1' },
        requests_as_source: [
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'failed', id: '1' },
          },
          {
            state: 'pending',
            library_type: 'A',
            submission: { state: 'ready', id: '2' },
          },
        ],
      },
      {
        position: { name: 'B1' },
        requests_as_source: [
          {
            state: 'pending',
            submission: { state: 'ready', id: '1' },
            library_type: 'A',
          },
        ],
      },
    ],
  }

  const validator = checkAllLibraryRequestsWithSameReadySubmissions()

  it('validates when all requests has same submissions', () => {
    expect(validator(plate)).toEqual({ valid: true })
  })

  it('fails when some requests are different', () => {
    expect(validator(plate2)).toEqual({
      valid: false,
      message:
        'The plate has different submissions in `ready` state across its wells. All submissions should be the same for every well.',
    })
  })
})

describe('checkPlateWithSameReadyLibrarySubmissions', () => {
  describe('when the received plates have the same submissions', () => {
    const plate = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'failed', id: '1' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '2' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '3' },
            },
          ],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '2' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '3' },
            },
          ],
        },
      ],
    }

    const plate2 = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '3' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '2' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'failed', id: '1' },
            },
          ],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [
            {
              state: 'pending',
              submission: { state: 'ready', id: '3' },
              library_type: 'A',
            },
            {
              state: 'pending',
              submission: { state: 'ready', id: '2' },
              library_type: 'A',
            },
          ],
        },
      ],
    }

    const validator = checkPlateWithSameReadyLibrarySubmissions({})

    it('validates when all requests has same submissions', () => {
      expect(validator(plate)).toEqual({ valid: true })
      expect(validator(plate2)).toEqual({ valid: true })
    })
  })

  describe('when the received plates have different submissions', () => {
    const plate = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'failed', id: '1' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '2' },
            },
          ],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [
            {
              state: 'pending',
              submission: { state: 'ready', id: '2' },
              library_type: 'A',
            },
          ],
        },
      ],
    }

    const plate2 = {
      wells: [
        {
          position: { name: 'A1' },
          requests_as_source: [
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'failed', id: '1' },
            },
            {
              state: 'pending',
              library_type: 'A',
              submission: { state: 'ready', id: '2' },
            },
          ],
        },
        {
          position: { name: 'B1' },
          requests_as_source: [
            {
              state: 'pending',
              submission: { state: 'ready', id: '1' },
              library_type: 'A',
            },
          ],
        },
      ],
    }

    const validator = checkPlateWithSameReadyLibrarySubmissions({})

    it('fails when some requests are different', () => {
      expect(validator(plate)).toEqual({ valid: true })
      expect(validator(plate2)).toEqual({
        valid: false,
        message:
          'The submission from this plate are different from the submissions from previous scanned plates in this screen.',
      })
    })
  })
})

describe('checkForUnacceptablePlatePurpose', () => {
  const plate1 = {
    purpose: { name: 'PurposeA' },
  }

  const plate2 = {
    purpose: { name: 'PurposeB' },
  }

  const plate3 = {}

  describe('when there is not a list of acceptable purposes', () => {
    const validator = checkForUnacceptablePlatePurpose([])

    it('validates when there is no list of acceptable purposes', () => {
      expect(validator(plate1)).toEqual({ valid: true })
    })
  })

  describe('when there is a list of acceptable purposes', () => {
    const validator = checkForUnacceptablePlatePurpose(['PurposeA', 'PurposeC'])

    it('validates when the plate has an acceptable purpose', () => {
      expect(validator(plate1)).toEqual({ valid: true })
    })

    it('fails when the plate has an unacceptable purpose', () => {
      expect(validator(plate2)).toEqual({
        valid: false,
        message: 'The scanned plate has an unacceptable plate purpose type (should be PurposeA or PurposeC)',
      })
    })

    it('fails when the plate does not have a purpose', () => {
      expect(validator(plate3)).toEqual({
        valid: false,
        message: 'The scanned plate does not have a plate purpose',
      })
    })
  })
})
