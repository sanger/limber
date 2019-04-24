// Calculate well name, enumerating by column. (0 => A1, 1 => B1...)
// Note: Simply switch division and module to enumerate by row.
const indexToName = function(index, numberOfRows) {
  const col = Math.floor(index / numberOfRows) + 1
  const row = String.fromCharCode((index % numberOfRows) + 65)
  return row + col
}

// Calculate well coordinates (starting at [0, 0] <= A1) from wellName.
const wellNameToCoordinate = function(wellName) {
  const row = wellName.toUpperCase().charCodeAt(0) - 65
  const column = Number.parseInt(wellName.substring(1)) - 1
  return [column, row]
}

// Calculate well name from wellCoordinate.
const wellCoordinateToName = function(wellCoordinate) {
  const column = wellCoordinate[0] + 1
  const row = String.fromCharCode(wellCoordinate[1] + 65)
  return `${row}${column}`
}

// Calculate well index, enumerating by column. (A1 => 0, B1 => 1...)
const nameToIndex = function(wellName, numberOfRows) {
  const [col, row] = wellNameToCoordinate(wellName)
  return col * numberOfRows + row
}

const quadrantTargetFor = function(plateIndex, wellName, rowOffset, colOffset) {
  const wellCoordinate = wellNameToCoordinate(wellName)
  const destinationRow = wellCoordinate[1] * 2 + rowOffset[plateIndex]
  const destinationColumn = wellCoordinate[0] * 2 + colOffset[plateIndex]
  return wellCoordinateToName([destinationColumn, destinationRow])
}

const requestsForWell = function(well) {
  return [...well.requests_as_source, ...well.aliquots.map(aliquot => aliquot.request)].filter(request => request)
}

export { indexToName, nameToIndex, wellNameToCoordinate, quadrantTargetFor, requestsForWell }
