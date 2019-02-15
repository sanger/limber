import { wellNameToCoordinate } from 'shared/wellHelpers'
import counter from 'shared/counter'

function byPool(well, tags, relIndex, _absIndex, offset, counters) {
  if(!counters[well.poolIndex]) {
    counters[well.poolIndex] = counter(offset)
  }
  const i = counters[well.poolIndex]()
  if(!tags[i]) { return -1 }
  return tags[i].index
}

function byPlateSeq(well, tags, relIndex, _absIndex, offset, counters) {
  if(!tags[relIndex + offset]) { return -1 }
  return tags[relIndex + offset].index
}

function byPlateFixed(well, tags, _relIndex, absIndex, offset, counters) {
  if(!tags[absIndex + offset]) { return -1 }
  return tags[absIndex + offset].index
}

function byRows(wells, plateDims, walker) {
  return wells.sort(compareWellsByRow).reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = wellCol + (plateDims.number_of_columns * wellRow)
    acc[well.position] = walker(well, relIndex, absIndex)
    return acc
  }, {})
}

function compareWellsByRow(wellA, wellB) {
  const [ wellACol, wellARow ] = wellNameToCoordinate(wellA.position)
  const [ wellBCol, wellBRow ] = wellNameToCoordinate(wellB.position)
  if(wellARow > wellBRow) {
    return 1
  } else if(wellBRow > wellARow) {
    return -1
  } else {
    return wellACol > wellBCol ? 1 : -1
  }
}

function byColumns(wells, plateDims, walker) {
  return wells.sort(compareWellsByColumn).reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = wellRow + (plateDims.number_of_rows * wellCol)
    acc[well.position] = walker(well, relIndex, absIndex)
    return acc
  }, {})
}

function compareWellsByColumn(wellA, wellB) {
  const [ wellACol, wellARow ] = wellNameToCoordinate(wellA.position)
  const [ wellBCol, wellBRow ] = wellNameToCoordinate(wellB.position)
  if(wellACol > wellBCol) {
    return 1
  } else if(wellBCol > wellACol) {
    return -1
  } else {
    return wellARow > wellBRow ? 1 : -1
  }
}

const walkingByFunctions = {
  'by_pool': byPool,
  'by_plate_seq': byPlateSeq,
  'by_plate_fixed': byPlateFixed
}
const directionFunctions = {
  'by_rows': byRows,
  'by_columns': byColumns
}

const calculateTagLayout = function (wells, plateDims, tgGrp1, tgGrp2, walkingByOpt, directionOpt, offset = 0) {
  if(!validParameters(wells, plateDims, tgGrp1, tgGrp2, walkingByOpt, directionOpt, offset)) { return null }

  const tags = extractTags(tgGrp1, tgGrp2)
  const counters = {}

  return directionFunctions[directionOpt](wells, plateDims, (well, relIndex, absIndex) => {
    return walkingByFunctions[walkingByOpt](well, tags, relIndex, absIndex, offset, counters)
  })
}

const validParameters = function (wells, plateDims, tgGrp1, tgGrp2, walkingByOpt, directionOpt, offset) {
  if(!wells) { return false }
  if(!plateDims) { return false }
  if(!(plateDims.number_of_rows > 0 && plateDims.number_of_columns > 0)) { return false }
  if(!(tgGrp1 || tgGrp2)) { return false }
  if(tgGrp1 && !tgGrp1.tags) { return false }
  if(tgGrp2 && !tgGrp2.tags) { return false }
  if(tgGrp1 && !(tgGrp1.tags.length > 0)) { return false }
  if(tgGrp2 && !(tgGrp2.tags.length > 0)) { return false }
  if(!walkingByOpt) { return false }
  if(!directionOpt) { return false }
  return true
}

const extractTags = function(tgGrp1, tgGrp2) {
  // key on i7 tags if available
  if(tgGrp1) { return tgGrp1.tags }
  if(tgGrp2) { return tgGrp2.tags }
}

export { calculateTagLayout }
