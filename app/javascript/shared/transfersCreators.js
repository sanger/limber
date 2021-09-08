const baseTransferCreator = function(transfers, extraParams = (_) => {}) {
  const transfersArray = new Array(transfers.length)
  for (let i = 0; i < transfers.length; i++) {
    transfersArray[i] = {
      source_plate: transfers[i].plateObj.plate.uuid,
      pool_index: transfers[i].plateObj.index + 1,
      source_asset: transfers[i].well.uuid,
      outer_request: transfers[i].request.uuid,
      new_target: { location: transfers[i].targetWell },
      ...extraParams(transfers[i])
    }
  }
  return transfersArray
}

const transferTubesCreator = function(transfers, extraParams = (_) => {}) {
  console.log("*** transferTubesCreator ***")
  console.log("*** transfers ***", transfers)
  const transfersArray = new Array(transfers.length)
  for (let i = 0; i < transfers.length; i++) {
    console.log("*** transfers[i] ***", transfers[i])
    transfersArray[i] = {
      source_tube: transfers[i].tubeObj.tube.uuid,
      pool_index: transfers[i].tubeObj.index + 1,
      source_asset: transfers[i].tube.receptacle.uuid,
      outer_request: null, // transfers[i].request.uuid,
      new_target: { location: transfers[i].targetWell },
      ...extraParams(transfers[i])
    }
  }
  console.log("*** transfersArray ***", transfersArray)
  return transfersArray
}

export {
  baseTransferCreator,
  transferTubesCreator
}
