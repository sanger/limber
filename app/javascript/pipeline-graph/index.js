// Mounts #graph and renders a summary of the limber pipelines source from
// pipelines.json

import convert from 'color-convert'

import cytoscape from 'cytoscape'
import elk from 'cytoscape-elk'

cytoscape.use(elk)

let cy = undefined

let pipelineColours = {}

const pipelineColourNode = function (node) {
  const pipeline = node.data('pipeline')
  return pipelineColours[pipeline] || '#666'
}

const calculatePipelineColours = function (sortedPipelines) {
  pipelineColours = {}
  // group the pipelines by the first two words of the name
  const pipelineGroups = {}
  sortedPipelines.forEach((pipeline) => {
    const key = pipeline.split(' ').slice(0, 2).join(' ')
    if (pipelineGroups[key] === undefined) {
      pipelineGroups[key] = []
    }
    pipelineGroups[key].push(pipeline)
  })

  // create the pipeline colours
  const numberOfPipelineGroups = Object.keys(pipelineGroups).length
  const hueStep = 360 / numberOfPipelineGroups
  let hue = 0

  for (const [pipelineGroup, pipelines] of Object.entries(pipelineGroups)) {
    const numberOfPipelinesInGroup = pipelines.length
    const saturationStep = 80 / numberOfPipelinesInGroup // 80% of the saturation range
    console.log(numberOfPipelinesInGroup, saturationStep)
    // for each pipeline within the group
    pipelines.map((pipeline, index) => {
      const saturation = 100 - index * saturationStep // start at 20% of the saturation range
      console.log(`${pipeline} ${hue} ${saturation}`)
      const hex = convert.hsv.hex(hue, 100, saturation)
      pipelineColours[pipeline] = `#${hex}`
    })
    hue += hueStep
  }
}

const renderPipelinesKey = function (pipelines) {
  const key = document.getElementById('pipelines-key')
  key.innerHTML = ''
  pipelines.forEach((pipeline) => {
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
  elk: {
    algorithm: 'layered',
    'elk.direction': 'DOWN',
    'elk.layered.spacing.nodeNodeBetweenLayers': 65, // The minimal distance to be preserved between each two nodes on different layers.
    'elk.spacing.nodeNode': 65, // The minimal distance to be preserved between each two nodes on the same layer.
  },
}

const renderPipelines = function (data) {
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
          'text-wrap': 'wrap',
          'text-max-width': '90',
        },
      },
      {
        selector: '[type = "plate"]',
        style: {
          shape: 'polygon',
          'shape-polygon-points': platePolygon,
          width: 48,
          height: 48,
        },
      },
      {
        selector: '[type = "tube"]',
        style: {
          shape: 'polygon',
          'shape-polygon-points': tubePolygon,
          width: 48,
          height: 48,
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
          'line-color': pipelineColourNode,
          'target-arrow-color': pipelineColourNode,
          'target-arrow-shape': 'triangle',
          'arrow-scale': 2,
        },
      },
    ],

    layout: layoutOptions,

    minZoom: 0.2,
    maxZoom: 3, // referenced in renderIcon above
  })

  const sortedPipelines = data.pipelines.map((pipeline) => pipeline.name).sort()
  calculatePipelineColours(sortedPipelines)
  renderPipelinesKey(sortedPipelines)
}

// Fetch the result of pipelines.json and then render the graph.
fetch('pipelines.json').then((response) => {
  response.json().then(renderPipelines)
})

const searchField = document.getElementById('search')
let notResults = undefined
searchField.addEventListener('change', (event) => {
  if (notResults !== undefined) {
    notResults.restore()
  }

  const query = event.target.value
  const all = cy.$('*')
  let results = cy.collection()
  results = results.union(cy.$(`edge[pipeline @^= "${query}"]`))
  results = results.union(results.connectedNodes())
  results = results.union(cy.$(`node[id @*= "${query}"]`))
  notResults = cy.remove(all.not(results))

  const sortedPipelines = [
    ...new Set( // remove duplicates
      results
        .edges()
        .map((edge) => edge.data('pipeline'))
        .sort()
    ),
  ]
  calculatePipelineColours(sortedPipelines)
  renderPipelinesKey(sortedPipelines)

  results.layout(layoutOptions).run()
})
