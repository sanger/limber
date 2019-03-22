import { extractParentWellSubmissionDetails, extractParentUsedOligos, extractChildUsedOligos } from './tagClashFunctions'
import {
  exampleParent,
  exampleParentWithPools,
  exampleTag1Oligos,
  exampleTag1and2Oligos
} from './testData/tagClashFunctionsTestData.js'

describe('extractParentWellSubmissionDetails', () => {
  it('returns expected values by position for a parent with one submission', () => {
    const parentPlate = exampleParent

    const exptParentWellSubmissionDetails = {
      'A1': { subm_id: '1', pool_index: 1 },
      'A2': { subm_id: '1', pool_index: 1 },
      'A3': { subm_id: '1', pool_index: 1 },
      'A4': { subm_id: '1', pool_index: 1 },
    }

    const response = extractParentWellSubmissionDetails(parentPlate)

    expect(response).toEqual(exptParentWellSubmissionDetails)
  })

  it('returns expected values by position for a parent with multiple submissions', () => {
    const parentPlate = exampleParentWithPools

    const exptParentWellSubmissionDetails = {
      'A1': { subm_id: '1', pool_index: 1 },
      'A2': { subm_id: '1', pool_index: 1 },
      'A3': { subm_id: '2', pool_index: 2 },
      'A4': { subm_id: '2', pool_index: 2 },
    }

    const response = extractParentWellSubmissionDetails(parentPlate)

    expect(response).toEqual(exptParentWellSubmissionDetails)
  })
})

describe('extractParentUsedOligos', () => {
  it('returns expected values by submission id for a parent with one submission', () => {
    const parentPlate = exampleParent

    const exptParentUsedOligos = {
      '1': {
        'AAAAAAAT:GGGGGGGT': [ 'submission' ],
        'TTTTTTTA:CCCCCCCA': [ 'submission' ],
        'AAAAAAAC:GGGGGGGC': [ 'submission' ],
        'TTTTTTTG:CCCCCCCG': [ 'submission' ],
        'AAAAAAAA:GGGGGGGA': [ 'submission' ]
      }
    }

    const response = extractParentUsedOligos(parentPlate)

    expect(response).toEqual(exptParentUsedOligos)
  })

  it('returns expected values by submission id for a parent with multiple submissions', () => {
    const parentPlate = exampleParentWithPools

    const exptParentUsedOligos = {
      '1': {
        'AAAAAAAT:GGGGGGGT': [ 'submission' ],
        'TTTTTTTA:CCCCCCCA': [ 'submission' ],
        'AAAAAAAC:GGGGGGGC': [ 'submission' ],
        'TTTTTTTG:CCCCCCCG': [ 'submission' ],
        'AAAAAAAA:GGGGGGGA': [ 'submission' ]
      },
      '2': {
        'GACTAAAA:CTGATTTT': [ 'submission' ],
        'GACTTTTT:CTGAAAAA': [ 'submission' ],
        'GACTGGGG:CTGACCCC': [ 'submission' ],
        'GACTCCCC:CTGAGGGG': [ 'submission' ]
      }
    }

    const response = extractParentUsedOligos(parentPlate)

    expect(response).toEqual(exptParentUsedOligos)
  })
})

describe('extractChildUsedOligos', () => {
  describe('single submission', () => {
    it('returns expected values when there are no tag clashes', () => {
      const parentUsedOligos = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetails = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '1', pool_index: 1 },
        'A4': { subm_id: '1', pool_index: 1 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = {}
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ],
          'CCCCAAAA:GGGGAAAA': [ 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],
          'CCCCGGGG:GGGGCCCC': [ 'A3' ],
          'CCCCAATT:GGGGAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmissionDetails, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there are no tag clashes and only using tag group 1', () => {
      const parentUsedOligos = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetails = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '1', pool_index: 1 },
        'A4': { subm_id: '1', pool_index: 1 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = {}
      const tagGroupOligoStrings = exampleTag1Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ],
          'CCCCAAAA': [ 'A1' ],
          'CCCCTTTT': [ 'A2' ],
          'CCCCGGGG': [ 'A3' ],
          'CCCCAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmissionDetails, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there is a tag clash with the submission', () => {
      const parentUsedOligos = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetails = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '1', pool_index: 1 },
        'A4': { subm_id: '1', pool_index: 1 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 15 }
      const tagSubstitutions = {}
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission', 'A4' ],
          'CCCCAAAA:GGGGAAAA': [ 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],
          'CCCCGGGG:GGGGCCCC': [ 'A3' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmissionDetails, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there are valid substitutions', () => {
      const parentUsedOligos = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetails = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '1', pool_index: 1 },
        'A4': { subm_id: '1', pool_index: 1 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = { 12: 13, 13: 12 }
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ],
          'CCCCAAAA:GGGGAAAA': [ 'A1' ],
          'CCCCGGGG:GGGGCCCC': [ 'A2' ],
          'CCCCTTTT:GGGGTTTT': [ 'A3' ],
          'CCCCAATT:GGGGAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmissionDetails, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when clashes are caused by substitutions', () => {
      const parentUsedOligos = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetails = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '1', pool_index: 1 },
        'A4': { subm_id: '1', pool_index: 1 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = { 12: 15, 14: 11 }
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission', 'A2' ],
          'CCCCAAAA:GGGGAAAA': [ 'A1', 'A4' ],
          'CCCCGGGG:GGGGCCCC': [ 'A3' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmissionDetails, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })
  })

  describe('pooled submission', () => {
    it('returns expected values by submission id when there are no tag clashes', () => {
      const parentUsedOligosForPools = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetailsForPools = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '2', pool_index: 2 },
        'A4': { subm_id: '2', pool_index: 2 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = {}
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ],
          'CCCCAAAA:GGGGAAAA': [ 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],

        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ],
          'CCCCGGGG:GGGGCCCC': [ 'A3' ],
          'CCCCAATT:GGGGAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligosForPools, parentWellSubmissionDetailsForPools, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there is a tag clash with one submission', () => {
      const parentUsedOligosForPools = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetailsForPools = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '2', pool_index: 2 },
        'A4': { subm_id: '2', pool_index: 2 },
      }
      const tagLayout = { 'A1': 15, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = {}
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission', 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],

        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ],
          'CCCCGGGG:GGGGCCCC': [ 'A3' ],
          'CCCCAATT:GGGGAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligosForPools, parentWellSubmissionDetailsForPools, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values with tag clashes in multiple submissions', () => {
      const parentUsedOligosForPools = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetailsForPools = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '2', pool_index: 2 },
        'A4': { subm_id: '2', pool_index: 2 },
      }
      const tagLayout = { 'A1': 15, 'A2': 12, 'A3': 16, 'A4': 14 }
      const tagSubstitutions = {}
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission', 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],

        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission', 'A3' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ],
          'CCCCAATT:GGGGAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligosForPools, parentWellSubmissionDetailsForPools, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values by submission id when there are valid substitutions', () => {
      const parentUsedOligosForPools = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetailsForPools = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '2', pool_index: 2 },
        'A4': { subm_id: '2', pool_index: 2 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = { 11: 14, 14: 11 }
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ],
          'CCCCAATT:GGGGAATT': [ 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],

        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ],
          'CCCCGGGG:GGGGCCCC': [ 'A3' ],
          'CCCCAAAA:GGGGAAAA': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligosForPools, parentWellSubmissionDetailsForPools, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when a substitution causes a clash', () => {
      const parentUsedOligosForPools = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission' ]
        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ]
        }
      }
      const parentWellSubmissionDetailsForPools = {
        'A1': { subm_id: '1', pool_index: 1 },
        'A2': { subm_id: '1', pool_index: 1 },
        'A3': { subm_id: '2', pool_index: 2 },
        'A4': { subm_id: '2', pool_index: 2 },
      }
      const tagLayout = { 'A1': 11, 'A2': 12, 'A3': 13, 'A4': 14 }
      const tagSubstitutions = { 11: 15, 13: 16 }
      const tagGroupOligoStrings = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        '1': {
          'AAAAAAAT:GGGGGGGT': [ 'submission' ],
          'TTTTTTTA:CCCCCCCA': [ 'submission' ],
          'AAAAAAAC:GGGGGGGC': [ 'submission' ],
          'TTTTTTTG:CCCCCCCG': [ 'submission' ],
          'AAAAAAAA:GGGGGGGA': [ 'submission', 'A1' ],
          'CCCCTTTT:GGGGTTTT': [ 'A2' ],

        },
        '2': {
          'GACTAAAA:CTGATTTT': [ 'submission' ],
          'GACTTTTT:CTGAAAAA': [ 'submission', 'A3' ],
          'GACTGGGG:CTGACCCC': [ 'submission' ],
          'GACTCCCC:CTGAGGGG': [ 'submission' ],
          'CCCCAATT:GGGGAATT': [ 'A4' ]
        }
      }

      const response = extractChildUsedOligos(parentUsedOligosForPools, parentWellSubmissionDetailsForPools, tagLayout, tagSubstitutions, tagGroupOligoStrings)

      expect(response).toEqual(exptSubmUsedTags)
    })
  })
})
