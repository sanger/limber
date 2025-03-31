const plateToPlateTransferCreator = function (transfers, extraParams = (_) => {}) {
  const transfersArray = new Array(transfers.length)
  for (let i = 0; i < transfers.length; i++) {
    transfersArray[i] = {
      source_plate: transfers[i].plateObj.plate.uuid,
      pool_index: transfers[i].plateObj.index + 1,
      source_asset: transfers[i].well.uuid,
      outer_request: transfers[i].request.uuid,
      new_target: { location: transfers[i].targetWell },
      ...extraParams(transfers[i]),
    }
  }
  return transfersArray
}

const transferTubesToPlateCreator = function (transfers, extraParams = (_) => {}) {
  const transfersArray = new Array(transfers.length)
  for (let i = 0; i < transfers.length; i++) {
    transfersArray[i] = {
      source_tube: transfers[i].tubeObj.tube.uuid,
      pool_index: transfers[i].tubeObj.index + 1,
      source_asset: transfers[i].tubeObj.tube.receptacle.uuid,
      outer_request: null,
      new_target: { location: transfers[i].targetWell },
      ...extraParams(transfers[i]),
    }
  }
  return transfersArray
}

// TODO: needed?
// const transferTubesToTubeCreator = function (transfers, extraParams = (_) => {}) {
//   const transfersArray = new Array(transfers.length)
//   transfersArray = {
//     source_tube1: transfers[0].tubeObj[0].tube.uuid,
//     source_asset1: transfers[0].tubeObj[0].tube.receptacle.uuid,
//     source_tube2: transfers[1].tubeObj[1].tube.uuid,
//     source_asset2: transfers[1].tubeObj[1].tube.receptacle.uuid,
//     outer_request: null,
//     new_target: target_tube.uuid,
//     ...extraParams(transfers[0]),
//   }
//   return transfersArray
// }

export { plateToPlateTransferCreator, transferTubesToPlateCreator }
