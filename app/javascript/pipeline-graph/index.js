// Mounts #graph and renders a summary of the limber pipelines source from
// pipelines.json

import cytoscape from 'cytoscape'

// Distinct colours as used in the rest of limber
const colours = [
  '#FFFF00','#1CE6FF','#FF34FF','#FF4A46','#008941','#006FA6','#A30059','#FFDBE5',
  '#7A4900','#0000A6','#63FFAC','#B79762','#004D43','#8FB0FF','#997D87','#5A0007',
  '#809693','#FEFFE6','#1B4400','#4FC601','#3B5DFF','#4A3B53','#FF2F80','#61615A',
  '#BA0900','#6B7900','#00C2A0','#FFAA92','#FF90C9','#B903AA','#D16100','#DDEFFF',
  '#000035','#7B4F4B','#A1C299','#300018','#0AA6D8','#013349','#00846F','#372101',
  '#FFB500','#C2FFED','#A079BF','#CC0744','#C0B9B2','#C2FF99','#001E09','#00489C',
  '#6F0062','#0CBD66','#EEC3FF','#456D75','#B77B68','#7A87A1','#788D66','#885578',
  '#FAD09F','#FF8A9A','#D157A0','#BEC459','#456648','#0086ED','#886F4C','#34362D',
  '#B4A8BD','#00A6AA','#452C2C','#636375','#A3C8C9','#FF913F','#938A81','#575329',
  '#00FECF','#B05B6F','#8CD0FF','#3B9700','#04F757','#C8A1A1','#1E6E00','#7900D7',
  '#A77500','#6367A9','#A05837','#6B002C','#772600','#D790FF','#9B9700','#549E79',
  '#FFF69F','#201625','#72418F','#BC23FF','#99ADC0','#3A2465','#922329','#5B4534'
]

const pipelineColours = {}

const pipelineColour = function(node) {
  var pipeline = node.data('pipeline')
  if (pipelineColours[pipeline] === undefined ) {
    pipelineColours[pipeline] = colours.shift() || '#666'
  }
  return pipelineColours[pipeline]
}

// Polygon dimensions represent a series of points defined by alternating x,y co-ordinates
// They are bounded by the top left (-1,-1) and the bottom right (1,1)
// The polygons here begin with the upper left most position, and proceed round the shape
// clockwise
const platePolygon = '-1 -1 0.9 -1 1 -0.9 1 0.9 0.9 1 -0.9 1 -1 0.9'
const tubePolygon = '-1 -1 1 -1 1 -0.9 0.9 -0.9 0.9 0.75 0 1 -0.9 0.75 -0.9 -0.9 -1 -0.9'

const renderPipelines = function(data) {
  const container = document.getElementById('graph')
  const key = document.getElementById('pipelines-key')

  cytoscape({
    container, // container to render in

    elements: data.elements,

    style: [ // the stylesheet for the graph
      {
        selector: 'node',
        style: {
          'background-color': '#666',
          'label': 'data(id)',
          'color': 'white'
        }
      },
      {
        'selector': '[type = "plate"]',
        style: {
          'shape': 'polygon',
          'shape-polygon-points': platePolygon,
          'width': 127.76/2,
          'height': 85.47/2
        }
      },
      {
        'selector': '[type = "tube"]',
        style: {
          'shape': 'polygon',
          'shape-polygon-points': tubePolygon,
          'width': 27,
          'height': 80
        }
      },
      {
        selector: 'edge',
        style: {
          'width': 3,
          'curve-style': 'bezier',
          'line-color': pipelineColour,
          'target-arrow-color': pipelineColour,
          'target-arrow-shape': 'triangle'
        }
      }
    ],

    layout: {
      name: 'breadthfirst',
      grid: true
    },

    minZoom: 0.2,
    maxZoom: 3

  })

  data.pipelines.forEach((pipeline)=>{
    const item = document.createElement('li')
    const icon = document.createElement('span')
    icon.innerHTML = '+'
    icon.style = 'color: ' + pipelineColours[pipeline.name] + ';'
    item.innerHTML = pipeline.name
    item.appendChild(icon)
    key.appendChild(item)
  })
}

// Fetch the result of pipelines.json and then render the graph.
fetch('pipelines.json')
  .then((response) => { response.json().then(renderPipelines) })
