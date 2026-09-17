// Entrypoint for the pipeline visualiser page - reuses the pipeline overview graph styling
import colourMapping from '@/javascript/pipeline-graph/colourMapping.js'
import graph from '@/javascript/pipeline-graph/graphFunctions.js'

document.addEventListener('DOMContentLoaded', () => {
  const searchBtn = document.getElementById('search-btn')
  const barcodeInput = document.getElementById('barcode-input')
  const errorMessage = document.getElementById('error-message')
  const loading = document.getElementById('loading')
  const container = document.getElementById('graph')
  const pipelinesKey = document.getElementById('pipelines-key')

  // mirrors renderPipelinesKey in pipeline-graph/index.js, minus the click-to-filter behaviour
  const renderPipelinesKey = function (pipelineNames) {
    pipelinesKey.innerHTML = ''
    pipelineNames.forEach((pipeline) => {
      const item = document.createElement('li')
      const pipelineColour = colourMapping.getPipelineColour(pipeline)

      item.style.borderLeft = `solid 10px ${pipelineColour}`
      item.style.paddingLeft = '6px'
      item.textContent = pipeline

      const pipelinesAndGroups = 'edge[pipeline = "' + pipeline + '"],edge[group = "' + pipeline + '"]'
      item.addEventListener('mouseover', () => {
        graph.getElements(pipelinesAndGroups).addClass('highlight')
      })
      item.addEventListener('mouseout', () => {
        graph.getElements(pipelinesAndGroups).removeClass('highlight')
      })

      pipelinesKey.appendChild(item)
    })
  }

  // overrides on top of the shared stylesheet: our nodes carry a separate label field (barcode + purpose)
  // rather than reusing the id (which here is the labware uuid), and the searched labware gets a highlight
  const applyVisualiserStyleOverrides = function () {
    graph
      .getCore()
      .style()
      .selector('node')
      .style({ label: 'data(label)' })
      .selector('node[?searched]')
      .style({ 'border-width': 3, 'border-color': '#e8a838', 'border-style': 'solid' })
      .update()
  }

  async function searchBarcode() {
    const barcode = barcodeInput.value.trim()
    if (!barcode) {
      errorMessage.textContent = 'Please enter a barcode'
      errorMessage.style.display = 'block'
      return
    }

    errorMessage.style.display = 'none'
    loading.style.display = 'block'

    try {
      const response = await fetch(`/pipeline_visualiser/${encodeURIComponent(barcode)}.json`)
      if (!response.ok) throw new Error(`Barcode not found: ${barcode}`)

      const data = await response.json()
      loading.style.display = 'none'

      const pipelineNames = [
        ...new Set(data.graph_data.elements.map((ele) => ele.data.pipeline).filter(Boolean)),
      ].sort()
      colourMapping.calculatePipelineColours(pipelineNames)
      renderPipelinesKey(pipelineNames)

      graph.renderPipelines(container, data.graph_data)
      applyVisualiserStyleOverrides()
    } catch (error) {
      loading.style.display = 'none'
      errorMessage.textContent = `Error: ${error.message}`
      errorMessage.style.display = 'block'
    }
  }

  searchBtn.addEventListener('click', searchBarcode)
  barcodeInput.addEventListener('keypress', (e) => {
    if (e.key === 'Enter') searchBarcode()
  })

  // auto-run the search when arriving with a barcode already populated (e.g. from the relatives tab link)
  if (barcodeInput.value.trim()) searchBarcode()
})
