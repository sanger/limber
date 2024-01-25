// This file contains functions for filtering the graph based on different criteria

let notResults = undefined

// maintain the existing filters so that individual fields can be updated as required
let existingFilter = '' // default filter (show all)
let existingShowPipelineGroups = true // default (show groups)

let filterHistory = [existingFilter] // start with the existing (empty) filter

const hasPreviousFilter = () => filterHistory.length > 0

const getPreviousFilter = () => {
  filterHistory.pop() // remove the current filter
  return filterHistory.pop() // return the previous filter
}

/**
 * Searches for nodes and edges in a Cytoscape.js graph that match a given query.
 * Nodes are matched if their 'id' attribute contains the query string.
 * Edges are matched if their 'pipeline' or 'group' attribute starts with the query string.
 * The function also includes neighboring nodes of matched nodes and connected nodes of matched edges.
 * As a side-effect, all non-matching elements are removed from the graph.
 *
 * @param {cytoscape.Core} cy - The Cytoscape instance (i.e., the graph).
 * @param {Object} filter - The filter. It has two properties:
 *  - term: The filter term.
 *  - showPipelineGroups: Whether to show pipeline groups.
 * @returns {cytoscape.Collection} - A collection of nodes and edges that match the query.
 */
const findResults = (cy, filter) => {
  if (notResults !== undefined) {
    notResults.restore()
  }

  if (filter.term !== undefined && filter.term !== null)
    if (filterHistory[filterHistory.length - 1] !== filter) {
      // add filter term to (internal - not browser) history
      // don't add duplicate filters
      filterHistory.push(filter.term)
    }

  existingFilter = filter?.term ?? existingFilter
  existingShowPipelineGroups = filter?.showPipelineGroups ?? existingShowPipelineGroups

  const all = cy.$('*')
  let results = cy.collection()

  let edgeType = existingShowPipelineGroups ? 'group' : 'pipeline'

  let purposes = cy.$(`node[id @*= "${existingFilter}"]`)
  purposes = purposes.union(purposes.neighborhood(`node, edge[${edgeType}]`))
  results = results.union(purposes)

  let pipelines = cy.$(`edge[${edgeType}][${edgeType} @^= "${existingFilter}"]`)
  pipelines = pipelines.union(pipelines.connectedNodes())
  results = results.union(pipelines)

  notResults = cy.remove(all.not(results))

  return results
}

export default { hasPreviousFilter, getPreviousFilter, findResults }
