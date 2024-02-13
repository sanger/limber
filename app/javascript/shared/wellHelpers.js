// Calculate well name, enumerating by column. (0 => A1, 1 => B1...)
// Note: Simply switch division and module to enumerate by row.
const indexToName = function (index, numberOfRows) {
  const col = Math.floor(index / numberOfRows) + 1
  const row = String.fromCharCode((index % numberOfRows) + 65)
  return row + col
}

// Calculate well coordinates (starting at [0, 0] <= A1) from wellName.
const wellNameToCoordinate = function (wellName) {
  const row = wellName.toUpperCase().charCodeAt(0) - 65
  const column = Number.parseInt(wellName.substring(1)) - 1
  return [column, row]
}

// Calculate well name from wellCoordinate.
const wellCoordinateToName = function (wellCoordinate) {
  const column = wellCoordinate[0] + 1
  const row = String.fromCharCode(wellCoordinate[1] + 65)
  return `${row}${column}`
}

// Calculate well index, enumerating by column. (A1 => 0, B1 => 1...)
const nameToIndex = function (wellName, numberOfRows) {
  const [col, row] = wellNameToCoordinate(wellName)
  return col * numberOfRows + row
}

const quadrantTargetFor = function (plateIndex, wellName, rowOffset, colOffset) {
  const wellCoordinate = wellNameToCoordinate(wellName)
  const destinationRow = wellCoordinate[1] * 2 + rowOffset[plateIndex]
  const destinationColumn = wellCoordinate[0] * 2 + colOffset[plateIndex]
  return wellCoordinateToName([destinationColumn, destinationRow])
}

const requestsForWell = function (well) {
  return [...well.requests_as_source, ...well.aliquots.map((aliquot) => aliquot.request)].filter((request) => request)
}

const rowNumToLetter = function (value) {
  return String.fromCharCode(value + 64)
}

/* Given a list of items and an element, reduce the list to a unique set of items, and return the new idex of the provided element.
 * Used to colour wells by barcode.
 * @param {Array} items - The list of items to reduce.
 * @param {Object} element - The element to find the unique index of.
 * @returns {Number} - The unique index of the provided index.
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 0) => -1
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 1) => 0
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 2) => 1
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 3) => 2
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 4) => -1
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 5) => 3
 * @example - findUniqueIndex([5, 1, 2, 1, 2, 3], 6) => -1
 */
const findUniqueIndex = (items, element) => {
  const uniqueItems = [...new Set(items)]
  return uniqueItems.indexOf(element)
}

export {
  indexToName,
  nameToIndex,
  wellNameToCoordinate,
  quadrantTargetFor,
  requestsForWell,
  wellCoordinateToName,
  rowNumToLetter,
  findUniqueIndex,
}
