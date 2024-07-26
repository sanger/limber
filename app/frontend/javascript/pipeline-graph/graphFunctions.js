// This file contains functions for rendering the pipeline graph
import colourMapping from './colourMapping.js'

import cytoscape from 'cytoscape'
import elk from 'cytoscape-elk'
import popper from 'cytoscape-popper'

cytoscape.use(popper)
cytoscape.use(elk)

let cy = undefined

// Polygon dimensions represent a series of points defined by alternating x,y co-ordinates
// They are bounded by the top left (-1,-1) and the bottom right (1,1)
// The polygons here begin with the upper left most position, and proceed round the shape
// clockwise
const platePolygon = '-1.0 -0.6 0.85 -0.6 1.0 -0.45 1.0 0.45 0.85 0.6 -0.85 0.6 -1.0 0.45'
const tubePolygon = '-0.35 -1 0.35 -1 0.35 -0.55 0.28 -0.55 0.28 0.75 0 1 -0.28 0.75 -0.28 -0.55 -0.35 -0.55'

const renderNodeSize = function (canvas, size) {
  // Get the context of the canvas
  const ctx = canvas.getContext('2d')

  // Write the node size in the center
  ctx.font = 'bold 52px sans-serif'
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  ctx.fillStyle = 'white'
  ctx.fillText(size, canvas.width / 2, canvas.height / 2)
}

const renderNodeProperties = function (canvas, input, stock, cherrypickable_target) {
  // Get the context of the canvas
  const ctx = canvas.getContext('2d')

  // Draw bands to represent the node properties
  const bands = {
    input: { present: input, colour: 'cyan' },
    stock: { present: stock, colour: 'magenta' },
    cherrypickable_target: { present: cherrypickable_target, colour: 'yellow' },
  }
  const bandWidth = 3 * 3 // width of the coloured bands

  let bandOffset = 48 * 3 - bandWidth // start at the right of the canvas
  Object.keys(bands).forEach((band) => {
    if (bands[band].present) {
      ctx.fillStyle = bands[band].colour
      ctx.fillRect(bandOffset, 0, bandWidth, canvas.height)
      bandOffset -= bandWidth
    }
  })
}

const renderCanvas = function (size, input, stock, cherrypickable_target) {
  const isDefaultSize = size === null || size == 96
  if (isDefaultSize && !input && !stock && !cherrypickable_target) {
    // return a blank image
    return 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs='
  }

  // Create a temporary canvas
  const canvas = document.createElement('canvas')
  canvas.width = 48 * 3 // set canvas size to match node shape, with extra for zoom
  canvas.height = 48 * 3 // set canvas size to match node shape, with extra for zoom
  // NOTE: canvas is clipped to shape by cytoscape

  if (!isDefaultSize) renderNodeSize(canvas, size)
  renderNodeProperties(canvas, input, stock, cherrypickable_target)

  // Export the canvas to data URI
  const dataURI = canvas.toDataURL()
  return dataURI
}

// Dynamically create an icon based on the node's properties
const renderIcon = function (ele) {
  const size = ele.data('size')
  const input = ele.data('input')
  const stock = ele.data('stock')
  const cherrypickable_target = ele.data('cherrypickable_target')
  return renderCanvas(size, input, stock, cherrypickable_target)
}

const getElementPipeline = function (element) {
  return element.data('group') || element.data('pipeline')
}

const pipelineColourEdge = function (edge) {
  var pipeline = getElementPipeline(edge)
  return colourMapping.getPipelineColour(pipeline)
}

const updatePipelineColours = function () {
  cy.style().fromJson(styleOptions).update()
}

const getPipelineNamesFromCollection = function (collection) {
  return [...new Set(collection.edges().map((edge) => getElementPipeline(edge)))].sort()
}

// the stylesheet for the graph
const styleOptions = [
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
    selector: 'edge',
    style: {
      width: 3,
      'curve-style': 'bezier',
      'control-point-step-size': 15,
      'line-color': pipelineColourEdge,
      'target-arrow-color': pipelineColourEdge,
      'target-arrow-shape': 'triangle',
      'arrow-scale': 2,
    },
  },
  {
    selector: 'edge.highlight',
    style: {
      'underlay-opacity': 0.3,
    },
  },
]

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

const renderPipelines = function (container, data) {
  cy = cytoscape({
    container, // container to render in

    elements: data.elements,

    autoungrabify: true, // don't allow nodes to be dragged around

    // node dimensions:
    // - type: plate or tube
    // - size: number of wells
    // - input: true if the node is an input to the pipeline
    // TODO: add legend for the above

    style: styleOptions,
    layout: layoutOptions,

    minZoom: 0.2,
    maxZoom: 3, // referenced in renderIcon above
  })
}

const getCore = () => cy

const getElements = function (criteria) {
  return cy.elements(criteria)
}

const updateLayout = function (collection = cy) {
  collection.layout(layoutOptions).run()
}

export default {
  getCore,
  getElementPipeline,
  getElements,
  getPipelineNamesFromCollection,
  renderPipelines,
  updateLayout,
  updatePipelineColours,
}
