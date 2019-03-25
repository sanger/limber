
// Do NOT export this function. It mutates parameters that get passed in to it.
const _union = (collection, newEntries) => {
  return collection.concat(newEntries.split(',').filter((item) =>{ return !collection.includes(item) } ))
}

const _joinKeys = (object) => {
  return Object.entries(object).reduce((converted, [key, value]) => {
    converted[key] = value.join(',')
    return converted
  }, {})
}

const includeUnion = (inclusions) => {
  return inclusions.reduce(_union, []).join(',')
}

const fieldsUnion = (fields) => {
  const union = {}
  fields.forEach((field)=>{
    Object.entries(field).forEach(([key,value])=> {
      if (union[key] === undefined)  { union[key] = [] }
      union[key] = _union(union[key],value)
    })
  })
  return _joinKeys(union)
}

export { includeUnion, fieldsUnion }
