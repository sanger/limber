import { wellNameToCoordinate } from 'shared/wellHelpers'
import counter from 'shared/counter'

function byPool(well, tags, relIndex, _absIndex, offset, counters) {
  if(!counters[well.poolIndex]) {
    counters[well.poolIndex] = counter(offset)
  }
  const i = counters[well.poolIndex]()
  return (tags[i]) ? tags[i].index : -1
}

function byPlateSeq(well, tags, relIndex, _absIndex, offset, _counters) {
  return (tags[relIndex + offset]) ? tags[relIndex + offset].index : -1
}

function byPlateFixed(well, tags, _relIndex, absIndex, offset, _counters) {
  return (tags[absIndex + offset]) ? tags[absIndex + offset].index : -1
}

function byGroupByPlate(well, tags, relIndex, _absIndex, offset, _counters) {
  return (tags[relIndex + offset]) ? tags[relIndex + offset].index : -1
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

function byInverseRows(wells, plateDims, walker) {
  return wells.sort(compareWellsByRow).reverse().reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = (plateDims.number_of_columns * plateDims.number_of_rows) - (wellCol + (plateDims.number_of_columns * wellRow)) - 1
    acc[well.position] = walker(well, relIndex, absIndex)
    return acc
  }, {})
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

function byInverseColumns(wells, plateDims, walker) {
  return wells.sort(compareWellsByColumn).reverse().reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = (plateDims.number_of_columns * plateDims.number_of_rows) - (wellRow + (plateDims.number_of_rows * wellCol)) - 1
    acc[well.position] = walker(well, relIndex, absIndex)
    return acc
  }, {})
}

const walkingByFunctions = {
  'manual by pool': byPool,
  'manual by plate': byPlateSeq,
  'wells of plate': byPlateFixed,
  'as group by plate': byGroupByPlate
}
const directionFunctions = {
  'row': byRows,
  'column': byColumns,
  'inverse row': byInverseRows,
  'inverse column': byInverseColumns
}

const calculateTagLayout = function (data) {
  let validationResult = validateParameters(data)

  if(validationResult) {
    // TODO messages displayed where? some of these are valid first time
    console.log(validationResult.message)
    return null
  }

  const tags = extractTags(data.tag1Group, data.tag2Group)
  const counters = {}
  let offset = 0
  if(data.offsetTagByNumber && data.offsetTagByNumber > 0) {
    offset = data.offsetTagByNumber
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
      message: 'Neither tag group 1 or 2 parameters set'
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
  return (tag1Group) ? tag1Group.tags : tag2Group.tags
}

export { calculateTagLayout }
