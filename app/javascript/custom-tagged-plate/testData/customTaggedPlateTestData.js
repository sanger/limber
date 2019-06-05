const plateUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'

const exampleParent = {
  id: '1',
  uuid: plateUuid,
  name: 'Test Plate 123456',
  labware_barcode: { human_barcode: 'DN123456D' },
  state: 'passed',
  number_of_rows: 8,
  number_of_columns: 12,
  wells: [
    {
      id: '1',
      position: { name: 'A1' },
      poolIndex: 1,
      aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '2',
      position: { name: 'A2' },
      poolIndex: 1,
      aliquots: [{ id: '2', request: { id: '2', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '2', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '3',
      position: { name: 'A3' },
      poolIndex: 1,
      aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '3', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '4',
      position: { name: 'A4' },
      poolIndex: 1,
      aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '4', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    }
  ]
}

const exampleParentTag1Only = {
  id: '1',
  uuid: plateUuid,
  name: 'Test Plate 123456',
  labware_barcode: { human_barcode: 'DN123456D' },
  state: 'passed',
  number_of_rows: 8,
  number_of_columns: 12,
  wells: [
    {
      id: '1',
      position: { name: 'A1' },
      poolIndex: 1,
      aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT'],['TTTTTTTA'],['AAAAAAAC'],['TTTTTTTG'],['AAAAAAAA']] }}]
    },
    {
      id: '2',
      position: { name: 'A2' },
      poolIndex: 1,
      aliquots: [{ id: '2', request: { id: '2', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '2', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT'],['TTTTTTTA'],['AAAAAAAC'],['TTTTTTTG'],['AAAAAAAA']] }}]
    },
    {
      id: '3',
      position: { name: 'A3' },
      poolIndex: 1,
      aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '3', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT'],['TTTTTTTA'],['AAAAAAAC'],['TTTTTTTG'],['AAAAAAAA']] }}]
    },
    {
      id: '4',
      position: { name: 'A4' },
      poolIndex: 1,
      aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '4', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT'],['TTTTTTTA'],['AAAAAAAC'],['TTTTTTTG'],['AAAAAAAA']] }}]
    }
  ]
}

const exampleParentWithoutWellRequestsAsResource = {
  id: '1',
  uuid: plateUuid,
  name: 'Test Plate 123456',
  labware_barcode: { human_barcode: 'DN123456D' },
  state: 'passed',
  number_of_rows: 8,
  number_of_columns: 12,
  wells: [
    {
      id: '1',
      position: { name: 'A1' },
      poolIndex: 1,
      aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}}],
      requests_as_source: []
    },
    {
      id: '2',
      position: { name: 'A2' },
      poolIndex: 1,
      aliquots: [{ id: '2', request: { id: '2', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}}],
      requests_as_source: []
    },
    {
      id: '3',
      position: { name: 'A3' },
      poolIndex: 1,
      aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}}],
      requests_as_source: []
    },
    {
      id: '4',
      position: { name: 'A4' },
      poolIndex: 1,
      aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}}],
      requests_as_source: []
    }
  ]
}

const exampleParentSequential = {
  id: '1',
  uuid: plateUuid,
  name: 'Test Plate 123456',
  labware_barcode: { human_barcode: 'DN123456D' },
  state: 'passed',
  number_of_rows: 8,
  number_of_columns: 12,
  wells: [
    {
      id: '1',
      position: { name: 'A1' },
      poolIndex: 1,
      aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '2',
      position: { name: 'A2' },
      aliquots: [],
      requests_as_source: []
    },
    {
      id: '3',
      position: { name: 'A3' },
      poolIndex: 1,
      aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '3', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '4',
      position: { name: 'A4' },
      poolIndex: 1,
      aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '4', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    }
  ]
}

const exampleParentWithPools = {
  id: '1',
  uuid: plateUuid,
  name: 'Test Plate 123456',
  labware_barcode: { human_barcode: 'DN123456D' },
  state: 'passed',
  number_of_rows: 8,
  number_of_columns: 12,
  wells: [
    {
      id: '1',
      position: { name: 'A1' },
      poolIndex: 1,
      aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '2',
      position: { name: 'A2' },
      poolIndex: 1,
      aliquots: [{ id: '2', request: { id: '2', submission: { id: '1', name:'Subm 1' }}}],
      requests_as_source: [{ id: '2', submission: { id: '1', name:'Subm 1', used_tags:[['AAAAAAAT','GGGGGGGT'],['TTTTTTTA','CCCCCCCA'],['AAAAAAAC','GGGGGGGC'],['TTTTTTTG','CCCCCCCG'],['AAAAAAAA','GGGGGGGA']] }}]
    },
    {
      id: '3',
      position: { name: 'A3' },
      poolIndex: 2,
      aliquots: [{ id: '3', request: { id: '3', submission: { id: '2', name:'Subm 2' }}}],
      requests_as_source: [{ id: '3', submission: { id: '2', name:'Subm 2', used_tags:[['GACTAAAA','CTGATTTT'],['GACTTTTT','CTGAAAAA'],['GACTGGGG','CTGACCCC'],['GACTCCCC','CTGAGGGG']] }}]
    },
    {
      id: '4',
      position: { name: 'A4' },
      poolIndex: 2,
      aliquots: [{ id: '4', request: { id: '4', submission: { id: '2', name:'Subm 2' }}}],
      requests_as_source: [{ id: '4', submission: { id: '2', name:'Subm 2', used_tags:[['GACTAAAA','CTGATTTT'],['GACTTTTT','CTGAAAAA'],['GACTGGGG','CTGACCCC'],['GACTCCCC','CTGAGGGG']] }}]
    }
  ]
}

const nullTagGroup = {
  uuid: null,
  name: 'No tag group selected',
  tags: []
}

const exampleTag1Group = {
  id: '1',
  uuid: 'tag-1-group-uuid',
  name: 'Tag Group 1',
  tags: [
    { index: 11, oligo: 'CCCCAAAA' },
    { index: 12, oligo: 'CCCCTTTT' },
    { index: 13, oligo: 'CCCCGGGG' },
    { index: 14, oligo: 'CCCCAATT' },
    { index: 15, oligo: 'AAAAAAAA' },
    { index: 16, oligo: 'GACTTTTT' },
    { index: 17, oligo: 'CCCCAACC' }
  ]
}
const exampleTag2Group = {
  id: '2',
  uuid: 'tag-2-group-uuid',
  name: 'Tag Group 2',
  tags: [
    { index: 21, oligo: 'GGGGAAAA' },
    { index: 22, oligo: 'GGGGTTTT' },
    { index: 23, oligo: 'GGGGCCCC' },
    { index: 24, oligo: 'GGGGAATT' },
    { index: 25, oligo: 'GGGGGGGA' },
    { index: 26, oligo: 'CTGAAAAA' }
  ]
}

const exampleTag2GroupLonger = {
  id: '3',
  uuid: 'tag-2-group-uuid',
  name: 'Tag Group 2 longer',
  tags: [
    { index: 21, oligo: 'GGGGAAAA' },
    { index: 22, oligo: 'GGGGTTTT' },
    { index: 23, oligo: 'GGGGCCCC' },
    { index: 24, oligo: 'GGGGAATT' },
    { index: 25, oligo: 'GGGGGGGA' },
    { index: 26, oligo: 'CTGAAAAA' },
    { index: 27, oligo: 'CCTTCGCA' },
    { index: 28, oligo: 'GCAGCGCA' },
  ]
}

const exampleTag1GroupChromium = {
  id: '4',
  uuid: 'tag-1-group-uuid',
  name: 'Tag Group 1',
  tags: [
    { index: 1, oligo: 'CCCCAAAA' },
    { index: 2, oligo: 'CCCCTTTT' },
    { index: 3, oligo: 'CCCCGGGG' },
    { index: 4, oligo: 'CCCCAATT' },
    { index: 5, oligo: 'AAAAAAAA' },
    { index: 6, oligo: 'AAAATTTT' },
    { index: 7, oligo: 'AAAAGGGG' },
    { index: 8, oligo: 'AAAACCCC' },
    { index: 9, oligo: 'GGGGAAAA' },
    { index: 10, oligo: 'GGGGTTTT' },
    { index: 11, oligo: 'GGGGGGGG' },
    { index: 12, oligo: 'GGGGCCCC' },
    { index: 13, oligo: 'TTTTAAAA' },
    { index: 14, oligo: 'TTTTTTTT' },
    { index: 15, oligo: 'TTTTGGGG' },
    { index: 16, oligo: 'TTTTCCCC' }
  ]
}

const exampleTag1Oligos = {
  11: 'CCCCAAAA',
  12: 'CCCCTTTT',
  13: 'CCCCGGGG',
  14: 'CCCCAATT',
  15: 'AAAAAAAA',
  16: 'GACTTTTT',
  17: 'CCCCAACC'
}

const exampleTag2Oligos = {
  21: 'GGGGAAAA',
  22: 'GGGGTTTT',
  23: 'GGGGCCCC',
  24: 'GGGGAATT',
  25: 'GGGGGGGA',
  26: 'CTGAAAAA'
}

const exampleTag1and2Oligos = {
  11: 'CCCCAAAA:GGGGAAAA',
  12: 'CCCCTTTT:GGGGTTTT',
  13: 'CCCCGGGG:GGGGCCCC',
  14: 'CCCCAATT:GGGGAATT',
  15: 'AAAAAAAA:GGGGGGGA',
  16: 'GACTTTTT:CTGAAAAA'
}

const exampleChromiumTag1Oligos = {
  1: 'CCCCAAAA',
  2: 'CCCCTTTT',
  3: 'CCCCGGGG',
  4: 'CCCCAATT',
  5: 'AAAAAAAA',
  6: 'AAAATTTT',
  7: 'AAAAGGGG',
  8: 'AAAACCCC',
  9: 'GGGGAAAA',
  10: 'GGGGTTTT',
  11: 'GGGGGGGG',
  12: 'GGGGCCCC',
  13: 'TTTTAAAA',
  14: 'TTTTTTTT',
  15: 'TTTTGGGG',
  16: 'TTTTCCCC'
}

const nullQcableData = { plate: null, state: 'empty' }

const exampleQcableData = {
  plate: {
    id:'1',
    uuid: 'tag-plate-uuid',
    state:'available',
    labware_barcode: {
      human_barcode: 'TG12345678'
    },
    asset: {
      id:'1',
      uuid: 'asset-uuid'
    },
    lot: {
      id:'1',
      tag_layout_template: {
        id:'1',
        uuid: 'tag-template-uuid',
        direction:'row',
        walking_by:'wells of plate',
        tag_group: {
          id:'1',
          name:'i7 example tag group 1',
        },
        tag2_group: {
          id:'2',
          name:'i5 example tag group 2',
        }
      }
    }
  },
  state: 'valid'
}

const exampleParentUsedOligos = {
  '1': {
    'AAAAAAAT:GGGGGGGT': [ 'submission' ],
    'TTTTTTTA:CCCCCCCA': [ 'submission' ],
    'AAAAAAAC:GGGGGGGC': [ 'submission' ],
    'TTTTTTTG:CCCCCCCG': [ 'submission' ],
    'AAAAAAAA:GGGGGGGA': [ 'submission' ]
  }
}

const exampleChromiumParentUsedOligos = {
  '1': {
    'AAAAAAAT:GGGGGGGT:TTTTTTTA:CCCCCCCA': [ 'submission' ],
    'TTTTTTTA:CCCCCCCA:AAAAAAAT:GGGGGGGT': [ 'submission' ],
    'AAAAAAAC:GGGGGGGC:TTTTTTTG:CCCCCCCG': [ 'submission' ],
    'TTTTTTTG:CCCCCCCG:AAAAAAAC:GGGGGGGC': [ 'submission' ],
    'AAAAAAAA:GGGGGGGA:TTTTTTAA:CCCCCCAA': [ 'submission' ]
  }
}

const exampleParentWellSubmissionDetails = {
  'A1': { subm_id: '1', pool_index: 1 },
  'A2': { subm_id: '1', pool_index: 1 },
  'A3': { subm_id: '1', pool_index: 1 },
  'A4': { subm_id: '1', pool_index: 1 },
}

const exampleParentUsedOligosForPools = {
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

const exampleParentWellSubmissionDetailsForPools = {
  'A1': { subm_id: '1', pool_index: 1 },
  'A2': { subm_id: '1', pool_index: 1 },
  'A3': { subm_id: '2', pool_index: 2 },
  'A4': { subm_id: '2', pool_index: 2 },
}

const exampleTagGroupsList = {
  1: {
    id: '1',
    uuid: 'tag-1-group-uuid',
    name: 'Tag Group 1',
    tags: [
      {
        index: 1,
        oligo: 'CTAGCTAG'
      },
      {
        index: 2,
        oligo: 'TTATACGA'
      }
    ]
  },
  2: {
    id: '2',
    uuid: 'tag-2-group-uuid',
    name: 'Tag Group 2',
    tags: [
      {
        index: 1,
        oligo: 'CCTTAAGG'
      },
      {
        index: 2,
        oligo: 'AATTCGCA'
      }
    ]
  }
}

export {
  plateUuid,
  exampleParent,
  exampleParentTag1Only,
  exampleParentWithoutWellRequestsAsResource,
  exampleParentSequential,
  exampleParentWithPools,
  exampleTagGroupsList,
  nullTagGroup,
  exampleTag1Group,
  exampleTag2Group,
  exampleTag2GroupLonger,
  exampleTag1GroupChromium,
  exampleTag1Oligos,
  exampleTag2Oligos,
  exampleTag1and2Oligos,
  exampleChromiumTag1Oligos,
  nullQcableData,
  exampleQcableData,
  exampleParentUsedOligos,
  exampleChromiumParentUsedOligos,
  exampleParentWellSubmissionDetails,
  exampleParentUsedOligosForPools,
  exampleParentWellSubmissionDetailsForPools
}
