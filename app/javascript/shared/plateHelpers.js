import buildArray from './buildArray'

const buildPlateObjs = function(number) {
  return buildArray(number, (iteration) => {
    return { state: 'empty', plate: null, index: iteration } })
}

export default buildPlateObjs
