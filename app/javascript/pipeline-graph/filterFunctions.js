let notResults = undefined
// maintain the existing filters so that individual fields can be updated as required
let existingFilter = ''
let existingShowSubPipelines = false
/**
 * Searches for nodes and edges in a Cytoscape.js graph that match a given query.
 * Nodes are matched if their 'id' attribute contains the query string.
 * Edges are matched if their 'pipeline' attribute starts with the query string.
 * The function also includes neighboring nodes of matched nodes and connected nodes of matched edges.
 * As a side-effect, all non-matching elements are removed from the graph.
 *
 * @param {cytoscape.Core} cy - The Cytoscape instance (i.e., the graph).
 * @param {Object} filter - The filter. It has two properties:
 *  - term: The filter term.
 *  - showSubPipelines: Whether to show sub-pipelines.
 * @returns {cytoscape.Collection} - A collection of nodes and edges that match the query.
 */
const findResults = (cy, filter) => {
  if (notResults !== undefined) {
    notResults.restore()
  }

  existingFilter = filter?.term ?? existingFilter
  existingShowSubPipelines = filter?.showSubPipelines ?? existingShowSubPipelines

  const all = cy.$('*')
  let results = cy.collection()

  let edgeType = existingShowSubPipelines ? 'pipeline' : 'group'

  let purposes = cy.$(`node[id @*= "${existingFilter}"]`)
  purposes = purposes.union(purposes.neighborhood(`node, edge[${edgeType}]`))
  results = results.union(purposes)

  let pipelines = cy.$(`edge[${edgeType}][${edgeType} @^= "${existingFilter}"]`)
  pipelines = pipelines.union(pipelines.connectedNodes())
  results = results.union(pipelines)

  notResults = cy.remove(all.not(results))

  return results
}

export { findResults }
