import { findResults } from './filterFunctions'
import cytoscape from 'cytoscape'

describe('findResults', () => {
  const cy = cytoscape({
    elements: [
      { data: { id: 'plateA1' } },
      { data: { id: 'plateA2' } },
      { data: { id: 'plateB' } },
      { data: { id: 'plateC' } },
      { data: { id: 'edgeA1', source: 'plateA1', target: 'plateB', group: 'groupA' } },
      { data: { id: 'edgeA2', source: 'plateA2', target: 'plateB', group: 'groupA' } },
      { data: { id: 'edgeB', source: 'plateB', target: 'plateC', group: 'groupB' } },
      { data: { id: 'edge1', source: 'plateA1', target: 'plateB', pipeline: 'pipeline1' } },
      { data: { id: 'edge2', source: 'plateA2', target: 'plateB', pipeline: 'pipeline2' } },
      { data: { id: 'edge3', source: 'plateB', target: 'plateC', pipeline: 'pipeline3' } },
    ],
  })

  it('should return groups and associated purposes that match the query', () => {
    const filter = { term: 'groupA', showPipelineGroups: true }
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(5)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateA2')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('edgeA1')
    expect(resultsIds).toContain('edgeA2')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(5)
  })

  it('should return pipelines and associated purposes that match the query', () => {
    const filter = { term: 'pipeline1', showPipelineGroups: false }
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(3)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('edge1')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(3)
  })

  it('should return purposes and neighboring purposes and pipelines that match the query', () => {
    const filter = { term: 'plateA', showPipelineGroups: false } // matches plateA1 and plateA2
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(5)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateA2')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('edge1')
    expect(resultsIds).toContain('edge2')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(5)
  })

  it('should restore non-matching elements from previous search', () => {
    const filter1 = { term: 'pipeline1', showPipelineGroups: false }
    const results = findResults(cy, filter1)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(3)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('edge1')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(3)

    // search for a different query
    const filter2 = { term: 'pipeline2', showPipelineGroups: false }
    const results2 = findResults(cy, filter2)
    const resultsIds2 = results2.map((ele) => ele.id())

    expect(resultsIds2.length).toEqual(3)
    expect(resultsIds2).toContain('plateA2')
    expect(resultsIds2).toContain('plateB')
    expect(resultsIds2).toContain('edge2')

    // check that non-matching elements have been removed
    const all2 = cy.$('*')
    expect(all2.length).toEqual(3)
  })

  it('should retain the existing value of term', () => {
    const filter = { term: 'plateC', showPipelineGroups: true }
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(3)
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('plateC')
    expect(resultsIds).toContain('edgeB')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(3)

    // search for a different query
    const filter2 = { showPipelineGroups: false }
    const results2 = findResults(cy, filter2)
    const resultsIds2 = results2.map((ele) => ele.id())

    expect(resultsIds2.length).toEqual(3)
    expect(resultsIds2).toContain('plateB')
    expect(resultsIds2).toContain('plateC')
    expect(resultsIds2).toContain('edge3')

    // check that non-matching elements have been removed
    const all2 = cy.$('*')
    expect(all2.length).toEqual(3)
  })

  it('should retain the existing value of showPipelineGroups', () => {
    const filter = { term: 'pipeline1', showPipelineGroups: false }
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(3)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('edge1')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(3)

    // search for a different query
    const filter2 = { term: 'pipeline2' }
    const results2 = findResults(cy, filter2)
    const resultsIds2 = results2.map((ele) => ele.id())

    expect(resultsIds2.length).toEqual(3)
    expect(resultsIds2).toContain('plateA2')
    expect(resultsIds2).toContain('plateB')
    expect(resultsIds2).toContain('edge2')

    // check that non-matching elements have been removed
    const all2 = cy.$('*')
    expect(all2.length).toEqual(3)
  })

  it('should return empty collection if no elements match the query', () => {
    const filter = { term: 'no match' }
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(0)

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(0)
  })

  it('should return all elements if query is empty', () => {
    const filter = { term: '', showPipelineGroups: false }
    const results = findResults(cy, filter)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(7)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateA2')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('plateC')
    expect(resultsIds).toContain('edge1')
    expect(resultsIds).toContain('edge2')
    expect(resultsIds).toContain('edge3')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(7)
  })
})
