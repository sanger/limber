// Mounts #graph and renders a summary of the limber pipelines source from
// pipelines.json

import cytoscape from 'cytoscape'
import elk from 'cytoscape-elk'

cytoscape.use(elk)

// Distinct colours as used in the rest of limber
const colours = [
  '#FFFF00',
  '#1CE6FF',
  '#FF34FF',
  '#FF4A46',
  '#008941',
  '#006FA6',
  '#A30059',
  '#FFDBE5',
  '#7A4900',
  '#0000A6',
  '#63FFAC',
  '#B79762',
  '#004D43',
  '#8FB0FF',
  '#997D87',
  '#5A0007',
  '#809693',
  '#FEFFE6',
  '#1B4400',
  '#4FC601',
  '#3B5DFF',
  '#4A3B53',
  '#FF2F80',
  '#61615A',
  '#BA0900',
  '#6B7900',
  '#00C2A0',
  '#FFAA92',
  '#FF90C9',
  '#B903AA',
  '#D16100',
  '#DDEFFF',
  '#000035',
  '#7B4F4B',
  '#A1C299',
  '#300018',
  '#0AA6D8',
  '#013349',
  '#00846F',
  '#372101',
  '#FFB500',
  '#C2FFED',
  '#A079BF',
  '#CC0744',
  '#C0B9B2',
  '#C2FF99',
  '#001E09',
  '#00489C',
  '#6F0062',
  '#0CBD66',
  '#EEC3FF',
  '#456D75',
  '#B77B68',
  '#7A87A1',
  '#788D66',
  '#885578',
  '#FAD09F',
  '#FF8A9A',
  '#D157A0',
  '#BEC459',
  '#456648',
  '#0086ED',
  '#886F4C',
  '#34362D',
  '#B4A8BD',
  '#00A6AA',
  '#452C2C',
  '#636375',
  '#A3C8C9',
  '#FF913F',
  '#938A81',
  '#575329',
  '#00FECF',
  '#B05B6F',
  '#8CD0FF',
  '#3B9700',
  '#04F757',
  '#C8A1A1',
  '#1E6E00',
  '#7900D7',
  '#A77500',
  '#6367A9',
  '#A05837',
  '#6B002C',
  '#772600',
  '#D790FF',
  '#9B9700',
  '#549E79',
  '#FFF69F',
  '#201625',
  '#72418F',
  '#BC23FF',
  '#99ADC0',
  '#3A2465',
  '#922329',
  '#5B4534',
]

let cy = undefined
const pipelineColours = {}
const filterField = document.getElementById('filter')

const pipelineColourEdge = function (edge) {
  var pipeline = edge.data('pipeline')
  return pipelineColours[pipeline] || '#666'
}
const calculatePipelineColours = function (pipelineNames) {
  const coloursCopy = [...colours]
  pipelineNames.forEach((pipeline) => {
    const colour = coloursCopy.shift()
    pipelineColours[pipeline] = colour
  })
}

const renderPipelinesKey = function (pipelineNames) {
  const key = document.getElementById('pipelines-key')
  key.innerHTML = ''
  pipelineNames.forEach((pipeline) => {
    const item = document.createElement('li')
    const pipelineColour = pipelineColours[pipeline] || '#666'

    item.style.borderLeft = `solid 10px ${pipelineColour}`
    item.textContent = pipeline

    key.appendChild(item)
  })
}

// Polygon dimensions represent a series of points defined by alternating x,y co-ordinates
// They are bounded by the top left (-1,-1) and the bottom right (1,1)
// The polygons here begin with the upper left most position, and proceed round the shape
// clockwise
const platePolygon = '-1.0 -0.6 0.85 -0.6 1.0 -0.45 1.0 0.45 0.85 0.6 -0.85 0.6 -1.0 0.45'
const tubePolygon = '-0.35 -1 0.35 -1 0.35 -0.55 0.28 -0.55 0.28 0.75 0 1 -0.28 0.75 -0.28 -0.55 -0.35 -0.55'

// Dynamically create an icon based on the node's properties
const renderIcon = function (ele) {
  if (ele.data('size') === null || ele.data('size') == 96) {
    // return a blank image
    return 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs='
  }

  // Create a temporary canvas
  const canvas = document.createElement('canvas')
  canvas.width = 48 * 3 // set canvas size to match node shape, with extra for zoom
  canvas.height = 48 * 3 // set canvas size to match node shape, with extra for zoom
  // NOTE: canvas is clipped to shape by cytoscape

  // Get the context of the canvas
  const ctx = canvas.getContext('2d')

  // Write the node size in the center
  ctx.font = 'bold 64px sans-serif'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillStyle = ele.data('input') ? 'black' : 'white'
  ctx.fillText(ele.data('size'), canvas.width / 2, canvas.height / 2)

  // Export the canvas to data URI
  const dataURI = canvas.toDataURL()
  return dataURI
}

// for other layout options see https://js.cytoscape.org/#demos
// for elk options see https://eclipse.dev/elk/reference/algorithms/org-eclipse-elk-layered.html
const layoutOptions = {
  name: 'elk',
  transform: function (node, pos) {
    // A function that applies a transform to the final node position
    // scale x coordinates to prevent labels overlapping
    pos.x *= 2.25
    pos.y *= 1.35
    return pos
  },
  elk: {
    algorithm: 'layered',
    'elk.direction': 'DOWN',
  },
}

const renderPipelines = function (data) {
  const pipelines = data.pipelines.map((pipeline) => pipeline.name).sort()
  calculatePipelineColours(pipelines)
  renderPipelinesKey(pipelines)

  const container = document.getElementById('graph')

  cy = cytoscape({
    container, // container to render in

    elements: data.elements,

    autoungrabify: true, // don't allow nodes to be dragged around

    // node dimensions:
    // - type: plate or tube
    // - size: number of wells
    // - input: true if the node is an input to the pipeline
    // TODO: add legend for the above

    style: [
      // the stylesheet for the graph
      {
        selector: 'node',
        style: {
          'background-color': '#666',
          'background-image': renderIcon,
          'background-height': '100%', // set canvas to fit node
          'background-width': '100%', // set canvas to fit node
          label: 'data(id)',
          color: 'white',
          width: 48,
          height: 48,
          'text-halign': 'right',
          'text-valign': 'center',
          'text-wrap': 'wrap',
          'text-max-width': '90',
          'text-margin-x': '5',
        },
      },
      {
        selector: '[type = "plate"]',
        style: {
          shape: 'polygon',
          'shape-polygon-points': platePolygon,
        },
      },
      {
        selector: '[type = "tube"]',
        style: {
          shape: 'polygon',
          'shape-polygon-points': tubePolygon,
        },
      },
      {
        selector: '[?input]',
        style: {
          'background-color': '#ddd',
        },
      },
      {
        selector: 'edge',
        style: {
          width: 3,
          'curve-style': 'bezier',
          'control-point-step-size': 10,
          'line-color': pipelineColourEdge,
          'target-arrow-color': pipelineColourEdge,
          'target-arrow-shape': 'triangle',
          'arrow-scale': 2,
        },
      },
    ],

    layout: layoutOptions,

    minZoom: 0.2,
    maxZoom: 3, // referenced in renderIcon above
  })
}

// Fetch the result of pipelines.json and then render the graph.
fetch('pipelines.json').then((response) => {
  response.json().then((data) => {
    // Get filter from url
    const url = new URL(window.location.href)
    const filter = url.searchParams.get('filter')
    filterField.value = filter

    // Render the graph
    renderPipelines(data)

    // Apply filter if present
    if (filter) {
      applyFilter(filter)
    }
  })
})

let notResults = undefined
const applyFilter = function (query) {
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

  const pipelineNames = [...new Set(results.edges().map((edge) => edge.data('pipeline')))]
  calculatePipelineColours(pipelineNames)
  renderPipelinesKey(pipelineNames)

  results.layout(layoutOptions).run()
}

filterField.addEventListener('change', (event) => {
  const query = event.target.value

  // set url to reflect filter
  const url = new URL(window.location.href)
  url.searchParams.set('filter', query)
  window.history.pushState({}, '', url)

  applyFilter(query)
})
