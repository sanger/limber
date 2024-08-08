const valueConverter = (object, converter) => {
  const convertedObject = {}

  for (let key in object) {
    convertedObject[key] = converter(object[key])
  }

  return convertedObject
}

export default valueConverter
