const indexToName = function(index, numberOfColumns, numberOfRows) {
  var col = Math.floor(index / numberOfRows) + 1
  var row = String.fromCharCode((index % numberOfColumns) + 65)
  return row + col
}

const wellNameToCoordinate = function(wellName) {
  let row = wellName.charCodeAt(0) - 65
  let column = Number.parseInt(wellName.substring(1)) - 1
  return [column, row]
}

const wellCoordinateToName = function(wellCoordinate) {
  let column = wellCoordinate[0] + 1
  let row = String.fromCharCode(wellCoordinate[1] + 65)
  return `${row}${column}`
}

const requestsForWell = function(well) {
  return [...well.requests_as_source, ...well.aliquots.map(aliquot => aliquot.request)].filter(request => request)
}

export { indexToName, wellNameToCoordinate, wellCoordinateToName, requestsForWell }
