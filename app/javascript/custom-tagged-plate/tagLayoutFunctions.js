import { wellNameToCoordinate } from 'shared/wellHelpers'
import counter from 'shared/counter'

function byPool(well, tags, _relIndex, _absIndex, offset, counters) {
  if(!counters[well.pool_index]) {
    counters[well.pool_index] = counter(offset)
  }
  const i = counters[well.pool_index]()
  return tags[i] || -1
}

function byPlateSeq(_well, tags, relIndex, _absIndex, offset, _counters) {
  return tags[relIndex + offset] || -1
}

function byPlateFixed(_well, tags, _relIndex, absIndex, offset, _counters) {
  return tags[absIndex + offset] || -1
}

function byGroupByPlate(_well, tags, relIndex, _absIndex, offset, _counters) {
  return tags[relIndex + offset] || -1
}

function processTagsPerWell(acc, well, relIndex, absIndex, tagsPerWell, walker) {
  acc[well.position] = []
  let relIndexAdj = relIndex * tagsPerWell
  for (var i = 0; i < tagsPerWell; i++) {
    acc[well.position].push(walker(well, relIndexAdj, absIndex))
    relIndexAdj++
  }
  return acc
}

function retrieveWellCoords(wellA, wellB) {
  const [ wellACol, wellARow ] = wellNameToCoordinate(wellA.position)
  const [ wellBCol, wellBRow ] = wellNameToCoordinate(wellB.position)
  return [ wellACol, wellARow, wellBCol, wellBRow ]
}

function compareWellsByRow(wellA, wellB) {
  const [ wellACol, wellARow, wellBCol, wellBRow ] = retrieveWellCoords(wellA, wellB)
  if(wellARow > wellBRow) {
    return 1
  } else if(wellBRow > wellARow) {
    return -1
  } else {
    return wellACol > wellBCol ? 1 : -1
  }
}

function compareWellsByColumn(wellA, wellB) {
  const [ wellACol, wellARow, wellBCol, wellBRow ] = retrieveWellCoords(wellA, wellB)
  if(wellACol > wellBCol) {
    return 1
  } else if(wellBCol > wellACol) {
    return -1
  } else {
    return wellARow > wellBRow ? 1 : -1
  }
}

function byRows(wells, plateDims, tagsPerWell, walker) {
  return wells.sort(compareWellsByRow).reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = wellCol + (plateDims.number_of_columns * wellRow)
    return processTagsPerWell(acc, well, relIndex, absIndex, tagsPerWell, walker)
  }, {})
}

function byInverseRows(wells, plateDims, tagsPerWell, walker) {
  return wells.sort(compareWellsByRow).reverse().reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = (plateDims.number_of_columns * plateDims.number_of_rows) - (wellCol + (plateDims.number_of_columns * wellRow)) - 1
    return processTagsPerWell(acc, well, relIndex, absIndex, tagsPerWell, walker)
  }, {})
}

function byColumns(wells, plateDims, tagsPerWell, walker) {
  return wells.sort(compareWellsByColumn).reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = wellRow + (plateDims.number_of_rows * wellCol)
    return processTagsPerWell(acc, well, relIndex, absIndex, tagsPerWell, walker)
  }, {})
}

function byInverseColumns(wells, plateDims, tagsPerWell, walker) {
  return wells.sort(compareWellsByColumn).reverse().reduce((acc, well, relIndex) => {
    const [ wellCol, wellRow ] = wellNameToCoordinate(well.position)
    const absIndex = (plateDims.number_of_columns * plateDims.number_of_rows) - (wellRow + (plateDims.number_of_rows * wellCol)) - 1
    return processTagsPerWell(acc, well, relIndex, absIndex, tagsPerWell, walker)
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

/**
* Calculates the tag layout based on the user selections of tag group(s),
* walking by, direction and tag offset and the parent plate wells and
* dimensions.
* Returns an object of well position to tag map ids e.g. {"A1":1,"A2":2, etc.}
*/
const calculateTagLayout = function (data) {
  let validationResult = validateParameters(data)

  if(validationResult) {
    // TODO replace this with generic limber logging when available
    // console.log('WARNING: tagLayoutFunctions: ', validationResult.message)
    return {}
  }

  const tags = data.tagMapIds
  const counters = {}
  let offset = 0
  if(data.offsetTagsBy && data.offsetTagsBy > 0) {
    offset = data.offsetTagsBy * data.tagsPerWell
  }

  const filteredWells = data.wells.filter(well => well.aliquotCount > 0)

  return directionFunctions[data.direction](filteredWells, data.plateDims, data.tagsPerWell, (well, relIndex, absIndex) => {
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
    result = validateTagMapIds(data.tagMapIds)
  }

  if(!result) {
    result = validateWalkingBy(data.walkingBy)
  }

  if(!result) {
    result = validateDirection(data.direction)
  }

  if(!result) {
    result = validateTagsPerWell(data.tagsPerWell)
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

const validatePlateDims = function (plateDims) {
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

const validateTagMapIds = function (tagMapIds) {
  let result

  if(!tagMapIds) {
    result = {
      message: 'Tag map ids parameter not set'
    }
  } else if(tagMapIds.length <= 0) {
    result = {
      message: 'Tag map ids contains no tag ids'
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

const validateTagsPerWell = function (tagsPerWell) {
  let result

  if(!tagsPerWell || tagsPerWell <= 0) {
    result = {
      message: 'Tags per well parameter not set'
    }
  }

  return result
}

export { calculateTagLayout }
