import buildArray from './buildArray'

const buildTubeObjs = function(number) {
  return buildArray(number, (iteration) => {
    return { state: 'empty', labware: null, index: iteration }
  })
}

export {
  buildTubeObjs
}
