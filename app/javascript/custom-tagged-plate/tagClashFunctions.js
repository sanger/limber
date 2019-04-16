/**
 * Extracts the submission ids from the parent plate and returns an object that
 * contains submission id and pool index keyed by well position.
 * Used when calculating parent and child well objects and when building the
 * child used oligos object below.
 */
function extractParentWellSubmissionDetails(parentPlate) {
  if(!parentPlate) { return {} }

  let submissionPoolIndexes = {}
  let parentWellSubmissionDetails = {}
  let poolIndex = 0

  parentPlate.wells.forEach((well) => {
    const position = well.position.name

    if(well.aliquots && well.aliquots.length > 0) {
      const submDetails = extractSubmDetailsFromWell(well)

      if(!submDetails.id) {
        // TODO replace this with generic limber logging when available
        console.log('Tag clash functions: extractParentWellSubmissionDetails: Error: Submission Id not found for well')
        return
      }

      if(!(submDetails.id in submissionPoolIndexes)) {
        poolIndex++
        submissionPoolIndexes[submDetails.id] = poolIndex
      }

      parentWellSubmissionDetails[position] = {
        'subm_id': submDetails.id,
        'pool_index': submissionPoolIndexes[submDetails.id]
      }
    }
  })

  return parentWellSubmissionDetails
}

/**
 * Extracts the oligo strings already used in other plates for the submissions
 * present on the parent plate and returns an object that contains oligo
 * strings keyed by submission id.
 * Used when building the child used oligos object below.
 */
function extractParentUsedOligos(parentPlate) {
  if(!parentPlate) { return {} }

  let parentUsedOligos = {}

  parentPlate.wells.forEach((well) => {
    if(well.aliquots && well.aliquots.length > 0) {
      const submDetails = extractSubmDetailsFromWell(well)

      if(!submDetails.id) {
        // TODO replace this with generic limber logging when available
        console.log('Tag clash functions: extractParentUsedOligos: Error: Submission Id not found for well')
        return
      }

      parentUsedOligos[submDetails.id] = {}

      // add the submission used tags
      for (var i = 0; i < submDetails.usedTags.length; i++) {
        const oligoStr = submDetails.usedTags[i].join(':')
        parentUsedOligos[submDetails.id][oligoStr] = [ 'submission' ]
      }
    }
  })

  return parentUsedOligos
}


/**
 * Extracts the oligo strings the user has selected by their choice of tag
 * groups, layout and submissions, then combines them with the parent plate
 * used oligo object. The resulting object is keyed on submission id and oligo
 * string to identify locations that oligo string has been used.
 * Used to identify tag clashes when building the child wells object.
 */
function extractChildUsedOligos(parentUsedOligos, parentWellSubmDetails, tagLayout, tagSubstitutions, tagGroupOligos) {
  if(!isValidChildUsedOligoParameters(parentUsedOligos, parentWellSubmDetails, tagLayout, tagSubstitutions, tagGroupOligos)) { return {} }

  let childUsedOligos = JSON.parse(JSON.stringify(parentUsedOligos))

  Object.keys(tagLayout).forEach((position) => {
    const submId = parentWellSubmDetails[position]['subm_id']
    const tagMapIds = tagLayout[position]
    let oligos = []

    for (var i = 0; i < tagMapIds.length; i++) {
      let tagMapId = tagMapIds[i]

      // check for tag substitution
      if(tagSubstitutions.hasOwnProperty(tagMapId)) {
        tagMapId = tagSubstitutions[tagMapId]
      }

      oligos.push(tagGroupOligos[tagMapId])
    }

    const oligosStr = oligos.join(':')

    if(oligosStr in childUsedOligos[submId]) {
      childUsedOligos[submId][oligosStr].push(position)
    } else {
      childUsedOligos[submId][oligosStr] = [ position ]
    }
  })

  return childUsedOligos
}

function isValidChildUsedOligoParameters(parentUsedOligos, parentWellSubmDetails, tagLayout, tagSubstitutions, tagGroupOligos) {
  let isValid = true

  if(!parentUsedOligos) { isValid = false }
  if(!parentWellSubmDetails) { isValid = false }
  if(!tagLayout) { isValid = false }
  if(!tagSubstitutions) { isValid = false }
  if(!tagGroupOligos) { isValid = false }

  return isValid
}

function extractSubmDetailsFromWell(well) {
  let submDetails = extractSubmDetailsFromRequestsAsSource(well)

  if(!submDetails.id) {
    // backup method of getting to submission via aliquots if primary route fails
    submDetails = extractSubmDetailsFromAliquots(well)
  }

  return submDetails
}

function extractSubmDetailsFromRequestsAsSource(well) {
  let submDetails = { id: null, usedTags: [] }

  // N.B. using first request, possibly should be checking others
  if(well.requests_as_source[0] && well.requests_as_source[0].submission) {
    submDetails.id = well.requests_as_source[0].submission.id
    if(well.requests_as_source[0].submission.used_tags) {
      submDetails.usedTags = well.requests_as_source[0].submission.used_tags
    }
  }

  return submDetails
}

function extractSubmDetailsFromAliquots(well) {
  let submDetails = { id: null, usedTags: [] }

  // N.B. using first aliquot, possibly should be checking others
  if(well.aliquots[0] && well.aliquots[0].request && well.aliquots[0].request.submission) {
    submDetails.id = well.aliquots[0].request.submission.id
    if(well.aliquots[0].request.submission.used_tags) {
      submDetails.usedTags = well.aliquots[0].request.submission.used_tags
    }
  }

  return submDetails
}

export { extractParentWellSubmissionDetails, extractParentUsedOligos, extractChildUsedOligos }
