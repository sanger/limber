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
  console.log("*** transferCreators: transferTubesCreator ***")
  console.log("***transferCreators: transferTubesCreator: transfers ***", transfers)
  const transfersArray = new Array(transfers.length)
  for (let i = 0; i < transfers.length; i++) {
    console.log("*** transferCreators: transferTubesCreator: transfers[i] ***", transfers[i])
    console.log("*** transferCreators: transferTubesCreator: transfers[i].tubeObj.tube.uuid ***", transfers[i].tubeObj.tube.uuid)
    console.log("*** transferCreators: transferTubesCreator: transfers[i].tubeObj.tube.receptacle ***", transfers[i].tubeObj.tube.receptacle)
    console.log("*** transferCreators: transferTubesCreator: transfers[i].tubeObj.tube.receptacle.uuid ***", transfers[i].tubeObj.tube.receptacle.uuid)
    transfersArray[i] = {
      source_tube: transfers[i].tubeObj.tube.uuid,
      pool_index: transfers[i].tubeObj.index + 1,
      source_asset: transfers[i].tubeObj.tube.receptacle.uuid, // TODO: how to get source asset uuid for tube?
      outer_request: null, // transfers[i].request.uuid,
      new_target: { location: transfers[i].targetWell },
      ...extraParams(transfers[i])
    }
  }
  console.log("*** transferCreators: transferTubesCreator: transfersArray ***", transfersArray)
  return transfersArray
}

export {
  baseTransferCreator,
  transferTubesCreator
}
