import buildArray from './buildArray'

const buildTubeObjs = function (number) {
  return buildArray(number, (iteration) => {
    return { state: 'empty', labware: null, index: iteration }
  })
}

const purposeConfigForTube = function (tube, purposeConfigs) {
  const purposeUuid = tube?.purpose?.uuid
  return purposeConfigs ? purposeConfigs[purposeUuid] : undefined
}

export { buildTubeObjs, purposeConfigForTube }
