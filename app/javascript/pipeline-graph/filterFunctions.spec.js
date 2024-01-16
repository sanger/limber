import { findResults } from './filterFunctions'
import cytoscape from 'cytoscape'

describe('findResults', () => {
  const cy = cytoscape({
    elements: [
      { data: { id: 'plateA1' } },
      { data: { id: 'plateA2' } },
      { data: { id: 'plateB' } },
      { data: { id: 'plateC' } },
      { data: { id: 'edge1', source: 'plateA1', target: 'plateB', pipeline: 'pipeline1' } },
      { data: { id: 'edge2', source: 'plateA2', target: 'plateB', pipeline: 'pipeline2' } },
      { data: { id: 'edge3', source: 'plateB', target: 'plateC', pipeline: 'pipeline3' } },
    ],
  })

  it('should return pipelines and associated purposes that match the query', () => {
    const query = 'pipeline1'
    const results = findResults(cy, query)
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
    const query = 'plateA' // matches plateA1 and plateA2
    const results = findResults(cy, query)
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
    const query = 'pipeline1'
    const results = findResults(cy, query)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(3)
    expect(resultsIds).toContain('plateA1')
    expect(resultsIds).toContain('plateB')
    expect(resultsIds).toContain('edge1')

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(3)

    // search for a different query
    const query2 = 'pipeline2'
    const results2 = findResults(cy, query2)
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
    const query = 'no match'
    const results = findResults(cy, query)
    const resultsIds = results.map((ele) => ele.id())

    expect(resultsIds.length).toEqual(0)

    // check that non-matching elements have been removed
    const all = cy.$('*')
    expect(all.length).toEqual(0)
  })

  it('should return all elements if query is empty', () => {
    const query = ''
    const results = findResults(cy, query)
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
