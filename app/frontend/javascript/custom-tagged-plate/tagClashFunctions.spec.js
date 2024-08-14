import {
  extractParentWellSubmissionDetails,
  extractParentUsedOligos,
  extractChildUsedOligos,
} from './tagClashFunctions'
import {
  exampleParent,
  exampleParentWithPools,
  exampleTag1Oligos,
  exampleTag1and2Oligos,
  exampleParentUsedOligos,
  exampleChromiumTag1Oligos,
  exampleChromiumParentUsedOligos,
  exampleParentWellSubmissionDetails,
  exampleParentUsedOligosForPools,
  exampleParentWellSubmissionDetailsForPools,
} from './testData/customTaggedPlateTestData.js'

describe('extractParentWellSubmissionDetails', () => {
  it('returns empty details object when there is no parent plate', () => {
    const parentPlate = null

    const response = extractParentWellSubmissionDetails(parentPlate)

    expect(response).toEqual({})
  })

  it('returns expected values by position for a parent with one submission', () => {
    const parentPlate = exampleParent

    const exptParentWellSubmissionDetails = {
      A1: { subm_id: '1', pool_index: 1 },
      A2: { subm_id: '1', pool_index: 1 },
      A3: { subm_id: '1', pool_index: 1 },
      A4: { subm_id: '1', pool_index: 1 },
    }

    const response = extractParentWellSubmissionDetails(parentPlate)

    expect(response).toEqual(exptParentWellSubmissionDetails)
  })

  it('returns expected values by position for a parent with multiple submissions', () => {
    const parentPlate = exampleParentWithPools

    const exptParentWellSubmissionDetails = {
      A1: { subm_id: '1', pool_index: 1 },
      A2: { subm_id: '1', pool_index: 1 },
      A3: { subm_id: '2', pool_index: 2 },
      A4: { subm_id: '2', pool_index: 2 },
    }

    const response = extractParentWellSubmissionDetails(parentPlate)

    expect(response).toEqual(exptParentWellSubmissionDetails)
  })
})

describe('extractParentUsedOligos', () => {
  it('returns empty used oligos object when there is no parent plate', () => {
    const parentPlate = null

    const response = extractParentUsedOligos(parentPlate)

    expect(response).toEqual({})
  })

  it('returns expected values by submission id for a parent with one submission', () => {
    const parentPlate = exampleParent

    const exptParentUsedOligos = {
      1: {
        'AAAAAAAT:GGGGGGGT': ['submission'],
        'TTTTTTTA:CCCCCCCA': ['submission'],
        'AAAAAAAC:GGGGGGGC': ['submission'],
        'TTTTTTTG:CCCCCCCG': ['submission'],
        'AAAAAAAA:GGGGGGGA': ['submission'],
      },
    }

    const response = extractParentUsedOligos(parentPlate)

    expect(response).toEqual(exptParentUsedOligos)
  })

  it('returns expected values by submission id for a parent with multiple submissions', () => {
    const parentPlate = exampleParentWithPools

    const exptParentUsedOligos = {
      1: {
        'AAAAAAAT:GGGGGGGT': ['submission'],
        'TTTTTTTA:CCCCCCCA': ['submission'],
        'AAAAAAAC:GGGGGGGC': ['submission'],
        'TTTTTTTG:CCCCCCCG': ['submission'],
        'AAAAAAAA:GGGGGGGA': ['submission'],
      },
      2: {
        'GACTAAAA:CTGATTTT': ['submission'],
        'GACTTTTT:CTGAAAAA': ['submission'],
        'GACTGGGG:CTGACCCC': ['submission'],
        'GACTCCCC:CTGAGGGG': ['submission'],
      },
    }

    const response = extractParentUsedOligos(parentPlate)

    expect(response).toEqual(exptParentUsedOligos)
  })
})

describe('extractChildUsedOligos', () => {
  describe('single submission', () => {
    it('returns empty object if there is no parentUsedOligos', () => {
      const parentUsedOligos = null
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual({})
    })

    it('returns empty object if there is no parentWellSubmissionDetails', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = null
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual({})
    })

    it('returns empty object if there is no tagLayout', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = null
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual({})
    })

    it('returns empty object if there are no tagSubstitutions', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = null
      const tagGroupOligos = exampleTag1and2Oligos

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual({})
    })

    it('returns empty object if there are no tagGroupOligoStrings', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = null

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual({})
    })

    it('returns expected values when there are no tag clashes', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission'],
          'CCCCAAAA:GGGGAAAA': ['A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
          'CCCCGGGG:GGGGCCCC': ['A3'],
          'CCCCAATT:GGGGAATT': ['A4'],
        },
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values for a chromium plate when there are no tag clashes', () => {
      const parentUsedOligos = exampleChromiumParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = {
        A1: [1, 2, 3, 4],
        A2: [5, 6, 7, 8],
        A3: [9, 10, 11, 12],
        A4: [13, 14, 15, 16],
      }
      const tagSubs = {}
      const tagGroupOligos = exampleChromiumTag1Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT:TTTTTTTA:CCCCCCCA': ['submission'],
          'TTTTTTTA:CCCCCCCA:AAAAAAAT:GGGGGGGT': ['submission'],
          'AAAAAAAC:GGGGGGGC:TTTTTTTG:CCCCCCCG': ['submission'],
          'TTTTTTTG:CCCCCCCG:AAAAAAAC:GGGGGGGC': ['submission'],
          'AAAAAAAA:GGGGGGGA:TTTTTTAA:CCCCCCAA': ['submission'],
          'CCCCAAAA:CCCCTTTT:CCCCGGGG:CCCCAATT': ['A1'],
          'AAAAAAAA:AAAATTTT:AAAAGGGG:AAAACCCC': ['A2'],
          'GGGGAAAA:GGGGTTTT:GGGGGGGG:GGGGCCCC': ['A3'],
          'TTTTAAAA:TTTTTTTT:TTTTGGGG:TTTTCCCC': ['A4'],
        },
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there are no tag clashes and only using tag group 1', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission'],
          CCCCAAAA: ['A1'],
          CCCCTTTT: ['A2'],
          CCCCGGGG: ['A3'],
          CCCCAATT: ['A4'],
        },
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there is a tag clash with the submission', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [15] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission', 'A4'],
          'CCCCAAAA:GGGGAAAA': ['A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
          'CCCCGGGG:GGGGCCCC': ['A3'],
        },
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there are valid substitutions', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = { 12: 13, 13: 12 }
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission'],
          'CCCCAAAA:GGGGAAAA': ['A1'],
          'CCCCGGGG:GGGGCCCC': ['A2'],
          'CCCCTTTT:GGGGTTTT': ['A3'],
          'CCCCAATT:GGGGAATT': ['A4'],
        },
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when clashes are caused by substitutions', () => {
      const parentUsedOligos = exampleParentUsedOligos
      const parentWellSubmDets = exampleParentWellSubmissionDetails
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = { 12: 15, 14: 11 }
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission', 'A2'],
          'CCCCAAAA:GGGGAAAA': ['A1', 'A4'],
          'CCCCGGGG:GGGGCCCC': ['A3'],
        },
      }

      const response = extractChildUsedOligos(parentUsedOligos, parentWellSubmDets, tagLayout, tagSubs, tagGroupOligos)

      expect(response).toEqual(exptSubmUsedTags)
    })
  })

  describe('pooled submission', () => {
    it('returns expected values by submission id when there are no tag clashes', () => {
      const parentUsedOligosForPools = exampleParentUsedOligosForPools
      const parentWellSubmDetsForPools = exampleParentWellSubmissionDetailsForPools
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission'],
          'CCCCAAAA:GGGGAAAA': ['A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
        },
        2: {
          'GACTAAAA:CTGATTTT': ['submission'],
          'GACTTTTT:CTGAAAAA': ['submission'],
          'GACTGGGG:CTGACCCC': ['submission'],
          'GACTCCCC:CTGAGGGG': ['submission'],
          'CCCCGGGG:GGGGCCCC': ['A3'],
          'CCCCAATT:GGGGAATT': ['A4'],
        },
      }

      const response = extractChildUsedOligos(
        parentUsedOligosForPools,
        parentWellSubmDetsForPools,
        tagLayout,
        tagSubs,
        tagGroupOligos
      )

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when there is a tag clash with one submission', () => {
      const parentUsedOligosForPools = exampleParentUsedOligosForPools
      const parentWellSubmDetsForPools = exampleParentWellSubmissionDetailsForPools
      const tagLayout = { A1: [15], A2: [12], A3: [13], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission', 'A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
        },
        2: {
          'GACTAAAA:CTGATTTT': ['submission'],
          'GACTTTTT:CTGAAAAA': ['submission'],
          'GACTGGGG:CTGACCCC': ['submission'],
          'GACTCCCC:CTGAGGGG': ['submission'],
          'CCCCGGGG:GGGGCCCC': ['A3'],
          'CCCCAATT:GGGGAATT': ['A4'],
        },
      }

      const response = extractChildUsedOligos(
        parentUsedOligosForPools,
        parentWellSubmDetsForPools,
        tagLayout,
        tagSubs,
        tagGroupOligos
      )

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values with tag clashes in multiple submissions', () => {
      const parentUsedOligosForPools = exampleParentUsedOligosForPools
      const parentWellSubmDetsForPools = exampleParentWellSubmissionDetailsForPools
      const tagLayout = { A1: [15], A2: [12], A3: [16], A4: [14] }
      const tagSubs = {}
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission', 'A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
        },
        2: {
          'GACTAAAA:CTGATTTT': ['submission'],
          'GACTTTTT:CTGAAAAA': ['submission', 'A3'],
          'GACTGGGG:CTGACCCC': ['submission'],
          'GACTCCCC:CTGAGGGG': ['submission'],
          'CCCCAATT:GGGGAATT': ['A4'],
        },
      }

      const response = extractChildUsedOligos(
        parentUsedOligosForPools,
        parentWellSubmDetsForPools,
        tagLayout,
        tagSubs,
        tagGroupOligos
      )

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values by submission id when there are valid substitutions', () => {
      const parentUsedOligosForPools = exampleParentUsedOligosForPools
      const parentWellSubmDetsForPools = exampleParentWellSubmissionDetailsForPools
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = { 11: 14, 14: 11 }
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission'],
          'CCCCAATT:GGGGAATT': ['A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
        },
        2: {
          'GACTAAAA:CTGATTTT': ['submission'],
          'GACTTTTT:CTGAAAAA': ['submission'],
          'GACTGGGG:CTGACCCC': ['submission'],
          'GACTCCCC:CTGAGGGG': ['submission'],
          'CCCCGGGG:GGGGCCCC': ['A3'],
          'CCCCAAAA:GGGGAAAA': ['A4'],
        },
      }

      const response = extractChildUsedOligos(
        parentUsedOligosForPools,
        parentWellSubmDetsForPools,
        tagLayout,
        tagSubs,
        tagGroupOligos
      )

      expect(response).toEqual(exptSubmUsedTags)
    })

    it('returns expected values when a substitution causes a clash', () => {
      const parentUsedOligosForPools = exampleParentUsedOligosForPools
      const parentWellSubmDetsForPools = exampleParentWellSubmissionDetailsForPools
      const tagLayout = { A1: [11], A2: [12], A3: [13], A4: [14] }
      const tagSubs = { 11: 15, 13: 16 }
      const tagGroupOligos = exampleTag1and2Oligos

      const exptSubmUsedTags = {
        1: {
          'AAAAAAAT:GGGGGGGT': ['submission'],
          'TTTTTTTA:CCCCCCCA': ['submission'],
          'AAAAAAAC:GGGGGGGC': ['submission'],
          'TTTTTTTG:CCCCCCCG': ['submission'],
          'AAAAAAAA:GGGGGGGA': ['submission', 'A1'],
          'CCCCTTTT:GGGGTTTT': ['A2'],
        },
        2: {
          'GACTAAAA:CTGATTTT': ['submission'],
          'GACTTTTT:CTGAAAAA': ['submission', 'A3'],
          'GACTGGGG:CTGACCCC': ['submission'],
          'GACTCCCC:CTGAGGGG': ['submission'],
          'CCCCAATT:GGGGAATT': ['A4'],
        },
      }

      const response = extractChildUsedOligos(
        parentUsedOligosForPools,
        parentWellSubmDetsForPools,
        tagLayout,
        tagSubs,
        tagGroupOligos
      )

      expect(response).toEqual(exptSubmUsedTags)
    })
  })
})
