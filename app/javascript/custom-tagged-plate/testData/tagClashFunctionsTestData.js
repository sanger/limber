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

const exampleTag1Oligos = { 11: 'CCCCAAAA', 12: 'CCCCTTTT', 13: 'CCCCGGGG', 14: 'CCCCAATT', 15: 'AAAAAAAA', 16: 'GACTTTTT', 17: 'CCCCAACC' }
const exampleTag2Oligos = { 21: 'GGGGAAAA', 22: 'GGGGTTTT', 23: 'GGGGCCCC', 24: 'GGGGAATT', 25: 'GGGGGGGA', 26: 'CTGAAAAA' }
const exampleTag1and2Oligos = { 11: 'CCCCAAAA:GGGGAAAA', 12: 'CCCCTTTT:GGGGTTTT', 13: 'CCCCGGGG:GGGGCCCC', 14: 'CCCCAATT:GGGGAATT', 15: 'AAAAAAAA:GGGGGGGA', 16: 'GACTTTTT:CTGAAAAA' }

const exampleChildWells = {
  A1: {
    position: 'A1',
    aliquotCount: 1,
    tagIndex: 11,
    submId: '1',
    pool_index: 1,
    validity: { valid: true, message: '' }
  },
  A2: {
    position: 'A2',
    aliquotCount: 1,
    tagIndex: 12,
    submId: '1',
    pool_index: 1,
    validity: { valid: true, message: '' }
  },
  A3: {
    position: 'A3',
    aliquotCount: 1,
    tagIndex: 13,
    submId: '1',
    pool_index: 1,
    validity: { valid: true, message: '' }
  },
  A4: {
    position: 'A4',
    aliquotCount: 1,
    tagIndex: 14,
    submId: '1',
    pool_index: 1,
    validity: { valid: true, message: '' }
  }
}

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

export {
  plateUuid,
  exampleParent,
  exampleParentTag1Only,
  exampleParentWithoutWellRequestsAsResource,
  exampleParentSequential,
  exampleParentWithPools,
  exampleTag1Group,
  exampleTag2Group,
  exampleTag2GroupLonger,
  exampleTag1Oligos,
  exampleTag2Oligos,
  exampleTag1and2Oligos,
  exampleChildWells,
  exampleQcableData,
  exampleParentUsedOligos,
  exampleParentWellSubmissionDetails,
  exampleParentUsedOligosForPools,
  exampleParentWellSubmissionDetailsForPools
}
