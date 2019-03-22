function extractParentWellSubmissionDetails(parentPlate) {
  let submissionPoolIndexes = {}
  let parentWellSubmissionDetails = {}
  let poolIndex = 0

  parentPlate.wells.forEach((well) => {
    const position = well.position.name

    if(well.aliquots && well.aliquots.length > 0) {
      const submDetails = extractSubmDetailsFromWell(well)

      if(!submDetails.id) {
        console.log('TAG CLASH FUNCTIONS: extractParentWellSubmissionDetails: Error: Submission Id not found for well')
        // TODO what to do here? should not happen
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

function extractParentUsedOligos(parentPlate) {
  let parentUsedOligos = {}

  parentPlate.wells.forEach((well) => {
    if(well.aliquots && well.aliquots.length > 0) {
      const submDetails = extractSubmDetailsFromWell(well)

      if(!submDetails.id) {
        console.log('TAG CLASH FUNCTIONS: extractParentUsedOligos: Error: Submission Id not found for well')
        // TODO what to do here? should not happen
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

function extractChildUsedOligos(parentUsedOligos, parentWellSubmissionDetails, tagLayout, tagSubstitutions, tagGroupOligoStrings) {
  let childUsedOligos = JSON.parse(JSON.stringify(parentUsedOligos))

  Object.keys(tagLayout).forEach((position) => {
    let tagMapId = tagLayout[position]

    // check for tag substitution
    if(tagSubstitutions.hasOwnProperty(tagMapId)) {
      tagMapId = tagSubstitutions[tagMapId]
    }

    // now need oligo string for the tagMapId, how??
    const oligoStr = tagGroupOligoStrings[tagMapId]
    const submId = parentWellSubmissionDetails[position]['subm_id']

    if(oligoStr in childUsedOligos[submId]) {
      childUsedOligos[submId][oligoStr].push(position)
    } else {
      childUsedOligos[submId][oligoStr] = [ position ]
    }
  })

  return childUsedOligos
}

function extractSubmDetailsFromWell(well) {
  let submDetails = extractSubmDetailsFromRequestsAsSource(well)

  if(!submDetails.id) {
    // backup method of getting to submission if primary route fails
    submDetails = extractSubmDetailsFromAliquots(well)
  }

  return submDetails
}

function extractSubmDetailsFromRequestsAsSource(well) {
  let submDetails = { id: null, usedTags: [] }

  if(well.requests_as_source[0] && well.requests_as_source[0].submission) {
    submDetails.id = well.requests_as_source[0].submission.id

    submDetails.usedTags = well.requests_as_source[0].submission.used_tags
    // TODO loop through additional requests if any? do we take first submission id we find?
  }

  return submDetails
}

function extractSubmDetailsFromAliquots(well) {
  let submDetails = { id: null, usedTags: [] }

  if(well.aliquots[0] && well.aliquots[0].request && well.aliquots[0].request.submission) {
    submDetails.id = well.aliquots[0].request.submission.id
    submDetails.usedTags = well.aliquots[0].request.submission.used_tags
    // TODO loop through additional aliquots if any? do we take first submission id we find?
  }

  return submDetails
}

export { extractParentWellSubmissionDetails, extractParentUsedOligos, extractChildUsedOligos }
