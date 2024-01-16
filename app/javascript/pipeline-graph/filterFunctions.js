let notResults = undefined
/**
 * Searches for nodes and edges in a Cytoscape.js graph that match a given query.
 * Nodes are matched if their 'id' attribute contains the query string.
 * Edges are matched if their 'pipeline' attribute starts with the query string.
 * The function also includes neighboring nodes of matched nodes and connected nodes of matched edges.
 * As a side-effect, all non-matching elements are removed from the graph.
 *
 * @param {cytoscape.Core} cy - The Cytoscape instance (i.e., the graph).
 * @param {string} query - The search term.
 * @returns {cytoscape.Collection} - A collection of nodes and edges that match the query.
 */
const findResults = (cy, query) => {
  if (notResults !== undefined) {
    notResults.restore()
  }

  const all = cy.$('*')
  let results = cy.collection()

  let purposes = cy.$(`node[id @*= "${query}"]`)
  purposes = purposes.union(purposes.neighborhood())
  results = results.union(purposes)

  let pipelines = cy.$(`edge[pipeline @^= "${query}"]`)
  pipelines = pipelines.union(pipelines.connectedNodes())
  results = results.union(pipelines)

  notResults = cy.remove(all.not(results))

  return results
}

export { findResults }
