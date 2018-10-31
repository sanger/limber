const indexToName = function(index, numberOfColumns, numberOfRows) {
  var col = Math.floor(index / numberOfRows) + 1
  var row = String.fromCharCode((index % numberOfColumns) + 65)
  return row + col
}

export { indexToName }
