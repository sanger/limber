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

function byPlateSeq(well, tags, relIndex, _absIndex, offset, _counters) {
  if(!tags[relIndex + offset]) { return -1 }
  return tags[relIndex + offset].index
}

function byPlateFixed(well, tags, _relIndex, absIndex, offset, _counters) {
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
  'wells in pools': byPool,
  'manual by plate': byPlateSeq,
  'wells of plate': byPlateFixed
}
const directionFunctions = {
  'row': byRows,
  'column': byColumns
}

const calculateTagLayout = function (data) {
  let validationResult = validateParameters(data)

  if(validationResult) {
    // TODO error messages displayed where?
    console.log(validationResult.message)
    return null
  }

  const tags = extractTags(data.tag1Group, data.tag2Group)
  const counters = {}
  let offset = 0
  if(data.startAtTagNumber && data.startAtTagNumber > 0) {
    offset = data.startAtTagNumber - 1
  }

  return directionFunctions[data.direction](data.wells, data.plateDims, (well, relIndex, absIndex) => {
    return walkingByFunctions[data.walkingBy](well, tags, relIndex, absIndex, offset, counters)
  })
}

const validateParameters = function (data) {
  let result

  if(!data) {
    result = {
      message: 'Data parameter not set'
    }
  }

  if(!result) {
    result = validateWells(data.wells)
  }

  if(!result) {
    result = validatePlateDims(data.plateDims)
  }

  if(!result) {
    result = validateTagGroups(data.tag1Group, data.tag2Group)
  }

  if(!result) {
    result = validateWalkingBy(data.walkingBy)
  }

  if(!result) {
    result = validateDirection(data.direction)
  }

  return result
}

const validateWells = function (wells) {
  let result

  if(!wells) {
    result = {
      message: 'Wells parameter not set'
    }
  }

  return result
}

const validatePlateDims = function(plateDims) {
  let result

  if(!plateDims) {
    result = {
      message: 'Plate dimensions parameter not set'
    }
  } else if(!(plateDims.number_of_rows > 0 && plateDims.number_of_columns > 0)) {
    result = {
      message: 'Plate dimension rows and columns must be greater than zero'
    }
  }

  return result
}

const validateTagGroups = function(tag1Group,tag2Group) {
  let result

  if(!(tag1Group || tag2Group)) {
    result = {
      message: 'Either tag group 1 or tag group 2 parameter not set'
    }
  } else if(tag1Group && !tag1Group.tags) {
    result = {
      message: 'Tag group 1 parameter contains no tags list'
    }
  } else if(tag2Group && !tag2Group.tags) {
    result = {
      message: 'Tag group 2 parameter contains no tags list'
    }
  } else if(tag1Group && !(tag1Group.tags.length > 0)) {
    result = {
      message: 'Tag group 1 parameter tags list contains no tags'
    }
  } else if(tag2Group && !(tag2Group.tags.length > 0)) {
    result = {
      message: 'Tag group 2 parameter tags list contains no tags'
    }
  }

  return result
}

const validateWalkingBy = function (walkingBy) {
  let result

  if(!walkingBy) {
    result = {
      message: 'Walking by parameter not set'
    }
  }

  return result
}

const validateDirection = function (direction) {
  let result

  if(!direction) {
    result = {
      message: 'Direction parameter not set'
    }
  }

  return result
}

const extractTags = function(tag1Group, tag2Group) {
  // key on i7 tags if available
  // TODO needs refactoring and a test
  if(tag1Group) { return tag1Group.tags }
  if(tag2Group) { return tag2Group.tags }
}

export { calculateTagLayout }
