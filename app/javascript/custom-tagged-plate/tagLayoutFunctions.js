import { wellNameToCoordinate } from 'shared/wellHelpers'
import counter from 'shared/counter'

function byPool(well, tags, relIndex, _absIndex, offset, counters) {
  if(!counters[well.poolId]) {
    counters[well.poolId] = counter(0)
  }
  const i = counters[well.poolId]()
  console.log('well ' + well.position + ' has tag counter ' + i)
  return tags[i].index
}

function byPlateSeq(well, tags, relIndex, _absIndex, offset, counters) {
  return tags[relIndex + offset].index
}

function byPlateFixed(well, tags, _relIndex, absIndex, offset, counters) {
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

const calculateTagLayout = function (wells, plateDims, tgGrp1, tgGrp2, walkingByOpt, directionOpt, offsetOpt) {
  console.log('calculateTagLayout: wells - ', wells)
  console.log('calculateTagLayout: tgGrp1 - ', tgGrp1)
  console.log('calculateTagLayout: tgGrp2 - ', tgGrp2)
  console.log('calculateTagLayout: walkingByOpt - ', walkingByOpt)
  console.log('calculateTagLayout: directionOpt - ', directionOpt)
  console.log('calculateTagLayout: offsetOpt - ', offsetOpt)

  if(!tgGrp1 && !tgGrp2) {
    console.log('No tag groups input, returning wells unchanged')
    return wells
  }

  const tags = tgGrp1.tags
  const counters = {}

  return directionFunctions[directionOpt](wells, plateDims, (well, relIndex, absIndex) => {
    return walkingByFunctions[walkingByOpt](well, tags, relIndex, absIndex, offsetOpt, counters)
  })
}

export { calculateTagLayout }
