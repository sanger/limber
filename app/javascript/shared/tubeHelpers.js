import buildArray from './buildArray'

const buildTubeObjs = function(number) {
  return buildArray(number, (iteration) => {
    return { state: 'empty', tube: null, index: iteration }
  })
}

// const requestsForTube = function(tube) {
//   return [...tube.receptacle.requests_as_source, ...tube.receptacle.aliquots.map(aliquot => aliquot.request)].filter(request => request)
// }

export {
  buildTubeObjs
}
